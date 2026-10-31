import AppKit
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class BuildStore: BuildLookup {
    private(set) var state = BuildState()
    private(set) var source: BuildSourceChoice = .main
    private(set) var schemes: [String] = []
    private(set) var manualSchemes: [String] = []
    private(set) var schemeSuggestions: [String]?
    private(set) var isLoadingSchemeSuggestions = false
    private(set) var hasLog = false
    private(set) var issues: [BuildIssue] = []
    @ObservationIgnored private var buildLog = BuildLog(maxLines: 20_000, trimSlack: 2_000)

    @ObservationIgnored let repository: any BuildRepository
    @ObservationIgnored let buildAndRun: BuildAndRunUseCase
    @ObservationIgnored let commandRun: CommandRunUseCase
    @ObservationIgnored private let prepareCheckout: PrepareBuildCheckoutUseCase
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let worktrees: any WorktreeLookup
    @ObservationIgnored let simulators: any SimulatorLookup
    @ObservationIgnored let identity: any IdentityLookup
    @ObservationIgnored let attacher: any XcodeAttaching
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored private let notifier: Notifier
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    private(set) var lastSourcePath: String?
    @ObservationIgnored private var runOptions: [String: SimulatorRunOptions]
    @ObservationIgnored private var buildTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private let suggestionsTask = RefreshTask()

    private static let targetKey = "simulators.target"
    private static let runOptionsKey = "simulators.runOptions"

    init(
        repository: any BuildRepository,
        buildAndRun: BuildAndRunUseCase,
        commandRun: CommandRunUseCase,
        prepareCheckout: PrepareBuildCheckoutUseCase,
        config: ConfigStore,
        session: ProjectSession,
        worktrees: any WorktreeLookup,
        simulators: any SimulatorLookup,
        identity: any IdentityLookup,
        attacher: any XcodeAttaching,
        activity: ActivityLog,
        notifier: Notifier,
        events: AppEvents,
        store: any KeyValueStore,
        prompts: any ReviewPromptRepository
    ) {
        self.repository = repository
        self.buildAndRun = buildAndRun
        self.commandRun = commandRun
        self.prepareCheckout = prepareCheckout
        self.config = config
        self.session = session
        self.worktrees = worktrees
        self.simulators = simulators
        self.identity = identity
        self.attacher = attacher
        self.activity = activity
        self.notifier = notifier
        self.events = events
        self.store = store
        self.prompts = prompts
        runOptions = store.decode([String: SimulatorRunOptions].self, forKey: Self.runOptionsKey) ?? [:]
        state.scheme = session.selectedProject.scheme
        manualSchemes = loadManualSchemes()
        let savedTarget = store.string(forKey: Self.targetKey)
        state.targetSimulatorID = savedTarget
        if let target = savedTarget {
            loadRunOptions(for: target)
        }
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                source = .main
                manualSchemes = loadManualSchemes()
                schemeSuggestions = nil
                Task { await self.refreshSchemes() }
            case .worktreesChanged:
                dropMissingSource()
            case .configChanged:
                Task { await self.refreshSchemes() }
            case .branchesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .appStateReported, .refreshRequested:
                break
            }
        }
    }

    func setProfile(_ id: LaunchProfile.ID) {
        state.profileID = id
        saveRunOptions()
    }

    var log: [String] {
        buildLog.lines
    }

    // MARK: Options

    func setScheme(_ scheme: String) {
        state.scheme = scheme
        saveRunOptions()
    }

    func setConfiguration(_ configuration: String) {
        state.configuration = configuration
        saveRunOptions()
    }

    func setIncremental(_ incremental: Bool) {
        state.incremental = incremental
        saveRunOptions()
    }

    func setCleanInstall(_ cleanInstall: Bool) {
        state.cleanInstall = cleanInstall
        saveRunOptions()
    }

    // MARK: Manual schemes

    func addScheme(_ name: String) {
        let updated = ManualSchemePolicy.adding(name, to: manualSchemes, visible: effective.schemes)
        guard updated != manualSchemes else { return }
        manualSchemes = updated
        saveManualSchemes()
        if let added = updated.last {
            setScheme(added)
        }
    }

    func removeScheme(_ name: String) {
        guard manualSchemes.contains(name) else { return }
        manualSchemes.removeAll { $0 == name }
        saveManualSchemes()
        guard state.scheme == name else { return }
        setScheme(effective.scheme ?? schemeOptions.first ?? session.selectedProject.scheme)
    }

    func loadSchemeSuggestions() async {
        guard isCommandProject == false else { return }
        isLoadingSchemeSuggestions = true
        await suggestionsTask.run { [weak self] in
            guard let self else { return }
            let listed: [String]
            do {
                listed = try await repository.listedSchemes(projectPath: session.selectedProject.path, container: container)
            } catch let error where (error is CancellationError) == false {
                schemeSuggestions = []
                activity.log("Could not list the schemes of the project", detail: error.localizedDescription, outcome: .failure)
                return
            }
            try Task.checkCancellation()
            schemeSuggestions = listed
        }
        isLoadingSchemeSuggestions = false
    }

    // MARK: Source

    func useSource(worktreeID: Worktree.ID?) {
        guard let worktreeID, worktrees.worktree(atPath: worktreeID)?.isMain == false else {
            source = .main
            saveRunOptions()
            return
        }
        source = .worktree(worktreeID)
        saveRunOptions()
    }

    func useSource(branch: String) {
        let local = BranchName(branch, remote: worktrees.gitSettings.remote).local
        if let path = worktrees.checkoutPath(forBranch: local) {
            useSource(worktreeID: path)
        } else {
            source = .branch(local)
            saveRunOptions()
        }
    }

    // MARK: Target

    func selectTarget(id: Simulator.ID) {
        guard state.targetSimulatorID != id else { return }
        state.targetSimulatorID = id
        store.set(id, forKey: Self.targetKey)
        loadRunOptions(for: id)
    }

    // MARK: Running

    func refreshSchemes() async {
        let project = session.selectedProject
        schemes = await repository.schemes(projectPath: project.path, container: container)
        let effective = effective
        let saved = state.targetSimulatorID.flatMap { runOptions[$0] }
        if saved == nil, state.configuration != effective.configuration {
            state.configuration = effective.configuration
        }
        guard let scheme = SchemeChoicePolicy.choose(
            available: ManualSchemePolicy.options(visible: effective.schemes, manual: manualSchemes),
            saved: saved?.scheme,
            configured: config.resolved.project.xcode?.scheme,
            current: state.scheme,
            projectDefault: effective.scheme ?? project.scheme
        ) else { return }
        state.scheme = scheme
    }

    enum Goal {
        case build
        case run
        case runAndAttach

        var launchesApp: Bool { self != .build }
        var attachesDebugger: Bool { self == .runAndAttach }
    }

    func run() {
        run(goal: .run)
    }

    func buildOnly() {
        run(goal: .build)
    }

    func runAndAttach() {
        guard isCommandProject == false else {
            activity.log("Run & Attach needs an Xcode project", detail: "This project builds with build.command and run.command.", outcome: .failure)
            return
        }
        guard ensureAccessibility() else { return }
        run(goal: .runAndAttach)
    }

    func writeFixPrompt() async -> String? {
        guard issues.contains(where: { $0.severity == .error }), let path = lastSourcePath else {
            activity.log("Nothing to fix", detail: "The last build has no compiler error.", outcome: .info)
            return nil
        }
        let prompt = FixPromptBuilder.build(scheme: state.scheme, checkoutName: path.abbreviatingHome, issues: issues)
        do {
            return try await prompts.save(prompt, name: FixPromptBuilder.fileName(forBuildOf: state.scheme))
        } catch {
            activity.log("Cannot write the fix prompt", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    func cancel() {
        buildTask?.cancel()
    }

    // MARK: Private

    private func run(goal: Goal) {
        guard let simulator = target, isRunning == false else { return }
        if state.targetSimulatorID != simulator.id {
            state.targetSimulatorID = simulator.id
            store.set(simulator.id, forKey: Self.targetKey)
        }
        let cleanInstall = willCleanInstall(on: simulator.id)
        let scheme = state.scheme
        let configuration = state.configuration
        let incremental = state.incremental
        let container = container
        let launch = launchPlan(for: simulator.id)
        let profileTitle = profile.map { " · \($0.title)" } ?? ""
        events.post(.buildStarted(simulatorID: simulator.id))
        buildLog.removeAll()
        hasLog = false
        issues = []
        state.phase = .running(step: "Preparing", progress: nil)
        saveRunOptions()
        buildTask = Task { [weak self] in
            guard let self else { return }
            var launchRecord: LaunchRecord?
            do {
                let prepared = try await prepare()
                try Task.checkCancellation()
                logPrepared(prepared)
                lastSourcePath = prepared.path
                let request = BuildRequest(
                    projectPath: prepared.path,
                    container: container,
                    scheme: scheme,
                    configuration: configuration,
                    incremental: incremental,
                    simulatorUDID: simulator.id,
                    simulatorName: simulator.name,
                    cleanInstall: cleanInstall,
                    launch: launch,
                    attachDebugger: goal.attachesDebugger,
                    launchesApp: goal.launchesApp
                )
                for try await event in events(for: request, prepared: prepared, simulator: simulator) {
                    if case .launched(let record) = event {
                        launchRecord = record
                    }
                    handle(event)
                }
                try Task.checkCancellation()
                state.phase = .succeeded(.now, launched: goal.launchesApp)
                let sourceName = prepared.worktreeName ?? prepared.path.abbreviatingHome
                switch goal {
                case .build:
                    activity.log("Built \(scheme)", detail: "\(configuration) · \(sourceName)", outcome: .success, kind: .build, target: .build)
                    notifier.buildFinished(title: "Built \(scheme)", detail: "\(configuration) · \(sourceName)", failed: false)
                case .run, .runAndAttach:
                    activity.log(goal.attachesDebugger ? "Launched \(scheme), Xcode attached" : "Launched \(scheme)", detail: "\(simulator.name) · \(configuration) · \(sourceName)\(profileTitle)", outcome: .success, kind: .build, target: .build)
                    notifier.buildFinished(title: "Launched \(scheme)", detail: "\(simulator.name) · \(sourceName)", failed: false)
                }
            } catch is CancellationError {
                state.phase = .idle
                activity.log("Build cancelled", detail: scheme, outcome: .info, kind: .build, target: .build)
            } catch {
                logCheckoutFailure(error)
                state.phase = .failed(error.localizedDescription)
                activity.log("Build failed", detail: error.localizedDescription, outcome: .failure, kind: .build, target: .build)
                notifier.buildFinished(title: "Build failed: \(scheme)", detail: error.localizedDescription, failed: true)
            }
            buildTask = nil
            events.post(.buildFinished(simulatorID: simulator.id, launch: launchRecord))
        }
    }

    private func prepare() async throws -> PrepareBuildCheckoutUseCase.Prepared {
        let prepared = try await prepareCheckout.execute(
            source: source,
            worktrees: worktrees.worktrees,
            mainCheckoutPath: worktrees.mainCheckoutPath,
            projectName: session.selectedProject.name,
            projectPath: session.selectedProject.path,
            baseBranch: worktrees.baseBranch,
            settings: worktrees.gitSettings,
            onStep: { [weak self] step in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    showPreparationStep(step)
                }
            },
            onBootstrap: { [events] path, isRunning in
                Task { @MainActor in
                    events.post(.worktreeBootstrapping(path: path, isRunning: isRunning))
                }
            }
        )
        if prepared.createdWorktree || prepared.bootstrapped {
            events.post(.worktreeCheckoutPrepared)
        }
        return prepared
    }

    private func showPreparationStep(_ step: String) {
        guard isRunning else { return }
        state.phase = .running(step: step, progress: nil)
    }

    static let issueLimit = 200

    private func handle(_ event: BuildEvent) {
        switch event {
        case .step(let title, let progress):
            if case .running(let current, _) = state.phase, current == title { return }
            state.phase = .running(step: title, progress: progress)
        case .output(let line):
            buildLog.append(line)
            if hasLog == false {
                hasLog = true
            }
        case .launched:
            break
        case .issue(let issue):
            guard issues.count < Self.issueLimit, issues.contains(issue) == false else { return }
            issues.append(issue)
        }
    }


    private func dropMissingSource() {
        guard worktrees.worktrees.isEmpty == false, case .worktree(let path) = source, worktrees.worktrees.contains(where: { $0.path == path }) == false else { return }
        source = .main
        saveRunOptions()
    }

    private func saveRunOptions() {
        guard let target = state.targetSimulatorID else { return }
        let options = SimulatorRunOptions(
            scheme: state.scheme,
            configuration: state.configuration,
            incremental: state.incremental,
            cleanInstall: state.cleanInstall,
            source: source,
            profileID: state.profileID
        )
        guard runOptions[target] != options else { return }
        runOptions[target] = options
        store.encode(runOptions, forKey: Self.runOptionsKey)
    }

    private var manualSchemesKey: String {
        "build.manualSchemes.\(session.selectedProjectID)"
    }

    private func loadManualSchemes() -> [String] {
        store.decode([String].self, forKey: manualSchemesKey) ?? []
    }

    private func saveManualSchemes() {
        store.encode(manualSchemes.isEmpty ? nil : manualSchemes, forKey: manualSchemesKey)
    }

    func savedProfileID(for id: Simulator.ID) -> LaunchProfile.ID? {
        runOptions[id]?.profileID
    }

    private func loadRunOptions(for id: Simulator.ID) {
        guard let options = runOptions[id] else { return }
        if schemes.isEmpty || schemes.contains(options.scheme) || manualSchemes.contains(options.scheme) {
            state.scheme = options.scheme
        }
        state.configuration = options.configuration
        state.incremental = options.incremental
        state.cleanInstall = options.cleanInstall
        state.profileID = options.profileID
        source = options.source
    }
}
