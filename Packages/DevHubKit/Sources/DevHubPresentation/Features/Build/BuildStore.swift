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
    private(set) var hasLog = false
    @ObservationIgnored private var buildLog = BuildLog(maxLines: 20_000, trimSlack: 2_000)

    @ObservationIgnored private let repository: any BuildRepository
    @ObservationIgnored private let buildAndRun: BuildAndRunUseCase
    @ObservationIgnored private let prepareCheckout: PrepareBuildCheckoutUseCase
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let worktrees: any WorktreeLookup
    @ObservationIgnored private let simulators: any SimulatorLookup
    @ObservationIgnored private let identity: any IdentityLookup
    @ObservationIgnored private let attacher: any XcodeAttaching
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var runOptions: [String: SimulatorRunOptions]
    @ObservationIgnored private var buildTask: Task<Void, Never>?
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let targetKey = "simulators.target"
    private static let runOptionsKey = "simulators.runOptions"

    init(
        repository: any BuildRepository,
        buildAndRun: BuildAndRunUseCase,
        prepareCheckout: PrepareBuildCheckoutUseCase,
        config: ConfigStore,
        session: ProjectSession,
        worktrees: any WorktreeLookup,
        simulators: any SimulatorLookup,
        identity: any IdentityLookup,
        attacher: any XcodeAttaching,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.repository = repository
        self.buildAndRun = buildAndRun
        self.prepareCheckout = prepareCheckout
        self.config = config
        self.session = session
        self.worktrees = worktrees
        self.simulators = simulators
        self.identity = identity
        self.attacher = attacher
        self.activity = activity
        self.events = events
        self.store = store
        runOptions = store.decode([String: SimulatorRunOptions].self, forKey: Self.runOptionsKey) ?? [:]
        state.scheme = session.selectedProject.scheme
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
                Task { await self.refreshSchemes() }
            case .worktreesChanged:
                dropMissingSource()
            case .configChanged:
                Task { await self.refreshSchemes() }
            case .branchesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .refreshRequested:
                break
            }
        }
    }

    var log: [String] {
        buildLog.lines
    }

    var isRunning: Bool {
        state.isRunning
    }

    var schemeOptions: [String] {
        let visible = effective.schemes
        return visible.isEmpty ? [state.scheme] : visible
    }

    var configurationOptions: [String] {
        var options = ["Debug", "Release"]
        for extra in [effective.configuration, state.configuration] where options.contains(extra) == false {
            options.append(extra)
        }
        return options
    }

    var effective: EffectiveProject {
        config.effective(detectedSchemes: schemes, detectedBaseBranch: worktrees.baseBranch)
    }

    private var container: String? {
        config.resolved.project.xcode?.container
    }

    var selectedScheme: String {
        state.scheme
    }

    var selectedConfiguration: String {
        state.configuration
    }

    var target: Simulator? {
        if let id = state.targetSimulatorID, let simulator = simulators.simulator(id: id) {
            return simulator
        }
        return simulators.all.first { $0.state == .booted } ?? simulators.all.first
    }

    func isTarget(_ id: Simulator.ID) -> Bool {
        target?.id == id
    }

    func willCleanInstall(on id: Simulator.ID) -> Bool {
        state.cleanInstall || profile?.cleanInstall == true || identity.needsCleanInstall(id: id)
    }

    var profiles: [LaunchProfile] {
        config.resolved.project.launch?.profiles ?? []
    }

    var profile: LaunchProfile? {
        profiles.first { $0.id == state.profileID } ?? profiles.first
    }

    func setProfile(_ id: LaunchProfile.ID) {
        state.profileID = id
        saveRunOptions()
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

    // MARK: Source

    var sourceWorktreeID: Worktree.ID? {
        sourceResolution.worktreeID
    }

    var sourcePath: String {
        sourceResolution.path
    }

    var sourceLabel: String {
        sourceResolution.label
    }

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
            available: effective.schemes,
            saved: saved?.scheme,
            configured: config.resolved.project.xcode?.scheme,
            current: state.scheme,
            projectDefault: effective.scheme ?? project.scheme
        ) else { return }
        state.scheme = scheme
    }

    func run() {
        run(attachDebugger: false)
    }

    func runAndAttach() {
        guard ensureAccessibility() else { return }
        run(attachDebugger: true)
    }

    func run(branch: String) {
        useSource(branch: branch)
        run()
    }

    func run(worktreeID: Worktree.ID) {
        useSource(worktreeID: worktreeID)
        run()
    }

    func run(on simulatorID: Simulator.ID) {
        selectTarget(id: simulatorID)
        run()
    }

    func cancel() {
        buildTask?.cancel()
    }

    func lastBuiltAppPath() -> String? {
        repository.lastBuiltAppPath(projectPath: sourcePath, container: container, scheme: state.scheme, configuration: state.configuration)
    }

    func showLog() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("DevHub-build.log")
        do {
            try log.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            NSWorkspace.shared.open(url)
        } catch {
            activity.log("Could not write build log", detail: error.localizedDescription, outcome: .failure)
        }
    }

    // MARK: Private

    private var sourceResolution: BuildSourceResolver.BuildSourceResolution {
        BuildSourceResolver.resolve(
            source: source,
            worktrees: worktrees.worktrees,
            mainCheckoutPath: worktrees.mainCheckoutPath,
            projectName: session.selectedProject.name,
            remote: worktrees.gitSettings.remote
        )
    }

    private func run(attachDebugger: Bool) {
        guard let simulator = target, isRunning == false else { return }
        if state.targetSimulatorID != simulator.id {
            state.targetSimulatorID = simulator.id
            store.set(simulator.id, forKey: Self.targetKey)
        }
        let buildIdentity = identity.buildIdentity(for: simulator.id)
        let cleanInstall = willCleanInstall(on: simulator.id)
        let scheme = state.scheme
        let configuration = state.configuration
        let incremental = state.incremental
        let container = container
        let launch = LaunchSettings(profile: profile)
        let profileTitle = profile.map { " · \($0.title)" } ?? ""
        events.post(.buildStarted(simulatorID: simulator.id))
        buildLog.removeAll()
        hasLog = false
        state.phase = .running(step: "Preparing", progress: nil)
        saveRunOptions()
        buildTask = Task { [weak self] in
            guard let self else { return }
            var launchedDeviceID: String??
            do {
                let prepared = try await prepare()
                try Task.checkCancellation()
                logPrepared(prepared)
                let request = BuildRequest(
                    projectPath: prepared.path,
                    container: container,
                    scheme: scheme,
                    configuration: configuration,
                    incremental: incremental,
                    simulatorUDID: simulator.id,
                    simulatorName: simulator.name,
                    identity: buildIdentity,
                    cleanInstall: cleanInstall,
                    launch: launch,
                    attachDebugger: attachDebugger
                )
                for try await event in buildAndRun.run(request) {
                    handle(event)
                }
                try Task.checkCancellation()
                state.phase = .succeeded(.now)
                if let buildIdentity {
                    launchedDeviceID = .some(buildIdentity.deviceID)
                }
                let sourceName = prepared.worktreeName ?? prepared.path.abbreviatingHome
                activity.log(attachDebugger ? "Launched \(scheme), Xcode attached" : "Launched \(scheme)", detail: "\(simulator.name) · \(configuration) · \(sourceName)\(profileTitle)", outcome: .success)
            } catch is CancellationError {
                state.phase = .idle
                activity.log("Build cancelled", detail: scheme, outcome: .info)
            } catch {
                logCheckoutFailure(error)
                state.phase = .failed(error.localizedDescription)
                activity.log("Build failed", detail: error.localizedDescription, outcome: .failure)
            }
            buildTask = nil
            events.post(.buildFinished(simulatorID: simulator.id, launchedDeviceID: launchedDeviceID))
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

    private func logPrepared(_ prepared: PrepareBuildCheckoutUseCase.Prepared) {
        let name = prepared.worktreeName ?? prepared.path.abbreviatingHome
        if prepared.createdWorktree {
            activity.log("Created worktree", detail: "\(name) · \(prepared.path.abbreviatingHome)", outcome: .success)
        }
        if prepared.bootstrapped {
            activity.log("Bootstrapped \(name)", detail: "\(worktrees.gitSettings.worktrees.bootstrap ?? "The bootstrap script") finished", outcome: .success)
        }
    }

    private func logCheckoutFailure(_ error: Error) {
        guard let error = error as? BuildSourceError else { return }
        switch error {
        case .worktreeNotCreated:
            break
        case .creationFailed(_, let message):
            activity.log("Could not create worktree", detail: message, outcome: .failure)
        case .bootstrapFailed(let name, let path, let createdWorktree, let message):
            if createdWorktree {
                activity.log("Created worktree", detail: "\(name) · \(path.abbreviatingHome)", outcome: .success)
            }
            activity.log("Bootstrap failed: \(name)", detail: "\(message) Full output in the Output panel.", outcome: .failure)
            events.post(.worktreeCheckoutPrepared)
        }
    }

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
        }
    }

    private func ensureAccessibility() -> Bool {
        guard attacher.isTrusted == false else { return true }
        attacher.requestTrust()
        activity.log("Allow DevHub in Accessibility", detail: "System Settings → Privacy & Security → Accessibility, then try again", outcome: .failure)
        return false
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

    private func loadRunOptions(for id: Simulator.ID) {
        guard let options = runOptions[id] else { return }
        if schemes.isEmpty || schemes.contains(options.scheme) {
            state.scheme = options.scheme
        }
        state.configuration = options.configuration
        state.incremental = options.incremental
        state.cleanInstall = options.cleanInstall
        state.profileID = options.profileID
        source = options.source
    }
}
