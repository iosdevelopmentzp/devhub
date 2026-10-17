import Foundation
import Observation

@MainActor
@Observable
final class BuildStore {
    private(set) var options: RunOptions
    private(set) var isCommandProject = false
    private(set) var schemes: [String] = []
    private(set) var configurationChoices: [String] = []
    private(set) var phase: BuildPhase = .idle
    private(set) var activeMode: RunMode?
    private(set) var attachNotice: AttachNotice?
    private(set) var statusText: String?
    private(set) var detectedBundleID: String?

    let worktrees: WorktreesStore

    @ObservationIgnored let provider: BuildProviding
    @ObservationIgnored let simulatorProvider: SimulatorProviding
    @ObservationIgnored let debugger: DebuggerAttaching
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let git: GitStore
    @ObservationIgnored let simulators: SimulatorsStore
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let preferences: AppPreferences
    @ObservationIgnored let projectActions: ProjectActions
    @ObservationIgnored private var buildTask: Task<Void, Never>?

    init(
        provider: BuildProviding,
        simulatorProvider: SimulatorProviding,
        debugger: DebuggerAttaching,
        session: ProjectSession,
        config: ConfigStore,
        git: GitStore,
        worktrees: WorktreesStore,
        simulators: SimulatorsStore,
        events: AppEvents,
        activity: ActivityLog,
        toaster: Toaster,
        preferences: AppPreferences,
        projectActions: ProjectActions
    ) {
        self.provider = provider
        self.simulatorProvider = simulatorProvider
        self.debugger = debugger
        self.session = session
        self.config = config
        self.git = git
        self.worktrees = worktrees
        self.simulators = simulators
        self.activity = activity
        self.toaster = toaster
        self.preferences = preferences
        self.projectActions = projectActions
        options = preferences.value(RunOptions.self, for: .runOptions) ?? .initial
        isCommandProject = config.effective?.kind == .command
        events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged, .configChanged:
                isCommandProject = config.effective?.kind == .command
                Task { await self.loadConfigurations() }
            case .branchesChanged, .worktreesChanged, .simulatorsChanged, .commandFailed:
                break
            }
        }
    }

    var isRunning: Bool { phase.isRunning }

    var target: SimulatorInfo? { simulators.target }

    var scheme: String { options.scheme ?? config.effective?.scheme ?? "" }

    var configuration: String { options.configuration ?? config.effective?.configuration ?? "Debug" }

    var source: BuildSource { options.source }

    var sourceChoices: [BuildSource] {
        var choices: [BuildSource] = [.main]
        choices += worktrees.worktrees.filter { $0.isMain == false && $0.isMissing == false }.map { .worktree($0.path) }
        let checkedOut = Set(worktrees.worktrees.compactMap(\.branch))
        choices += git.branches.local.filter { checkedOut.contains($0.name) == false }.map { .branch($0.name) }
        return choices
    }

    var profiles: [LaunchProfile] { config.config.launch?.profiles ?? [] }

    var profile: LaunchProfile? {
        guard let profileID = options.profileID else { return profiles.first }
        return profiles.first { $0.id == profileID } ?? profiles.first
    }

    var bundleID: String? { detectedBundleID ?? config.effective?.bundleID }

    var infoLine: String {
        let project = config.effective?.name ?? session.project?.name ?? "the project"
        if isCommandProject {
            return "Runs the configured command for \(project) from \(title(of: source))."
        }
        let named = scheme.isEmpty ? project : scheme
        return "Builds \(named) (\(configuration)) from \(title(of: source))."
    }

    func title(of source: BuildSource) -> String {
        switch source {
        case .main:
            if let branch = git.currentBranch { return "Main · \(branch)" }
            return "Main checkout"
        case let .worktree(path):
            if let info = worktrees.worktrees.first(where: { $0.path == path }) {
                return info.title
            }
            return (path as NSString).lastPathComponent
        case let .branch(name):
            return "Branch \(name)"
        }
    }

    func loadConfigurations() async {
        schemes = config.effective?.schemes ?? []
        guard isCommandProject == false, let container = config.effective?.container else {
            configurationChoices = []
            return
        }
        let found = await provider.configurations(container: container)
        configurationChoices = found.isEmpty ? ["Debug", "Release"] : found
    }

    func setOptions(_ mutate: (inout RunOptions) -> Void) {
        mutate(&options)
        preferences.setValue(options, for: .runOptions)
    }

    func chooseSource(_ value: BuildSource) {
        setOptions { $0.source = value }
        worktrees.setBuildSource(folder(for: value))
    }

    func start(_ mode: RunMode) {
        guard isRunning == false else { return }
        guard let simulator = target else {
            toaster.show("Pick a simulator first", tint: .orange)
            return
        }
        guard let folder = folder(for: source) else {
            fail("No worktree is checked out for \(title(of: source)). Create one in Worktrees.")
            return
        }
        activeMode = mode
        attachNotice = nil
        statusText = nil
        phase = .running("Starting \(mode.title)…")
        buildTask = Task { [weak self] in
            guard let self else { return }
            if isCommandProject {
                await runCommand(mode: mode, simulator: simulator, folder: folder)
            } else {
                await runXcode(mode: mode, simulator: simulator, folder: folder)
            }
            activeMode = nil
            statusText = nil
            buildTask = nil
        }
    }

    func cancel() {
        buildTask?.cancel()
        buildTask = nil
        activeMode = nil
        statusText = nil
        phase = .idle
    }

    func launch(on simulator: SimulatorInfo) {
        guard let bundleID else {
            toaster.show("Build once to learn the bundle ID", tint: .orange)
            return
        }
        simulators.markBusy(simulator.id, "Launching…")
        Task {
            defer { simulators.markBusy(simulator.id, nil) }
            let request = LaunchRequest(
                simulatorID: simulator.id,
                bundleID: bundleID,
                arguments: profile?.args ?? [],
                environment: profile?.env ?? [:],
                waitsForDebugger: false
            )
            do {
                _ = try await simulatorProvider.launch(request)
                activity.log("Launch", detail: "\(bundleID) on \(simulator.name)", outcome: .success)
                await simulators.refresh()
            } catch {
                activity.log("Launch", detail: error.localizedDescription, outcome: .failure)
                toaster.show("Launch failed: \(error.localizedDescription)", tint: .red)
            }
        }
    }

    func showLog() {
        guard case let .failed(failure) = phase, let path = failure.logPath else { return }
        Task { try? await provider.showLog(at: path) }
    }

    func dismissResult() {
        phase = .idle
        attachNotice = nil
    }

    func requestAccessibility() {
        debugger.requestAccess()
    }

    private func folder(for source: BuildSource) -> String? {
        switch source {
        case .main: session.project?.path
        case let .worktree(path): path
        case let .branch(name): worktrees.worktree(forBranch: name)?.path
        }
    }

    private func fail(_ message: String, logPath: String? = nil) {
        phase = .failed(BuildFailure(message: message, logPath: logPath))
        activity.log("Build", detail: message, outcome: .failure)
        toaster.show(message, tint: .red)
    }

    private func runXcode(mode: RunMode, simulator: SimulatorInfo, folder: String) async {
        let container = config.effective?.container ?? folder
        guard mode.builds else {
            await launchOnly(mode: mode, simulator: simulator, container: container)
            return
        }
        do {
            if simulator.isBooted == false {
                try await simulatorProvider.boot(simulator.id)
            }
            let request = BuildRequest(container: container, scheme: scheme, configuration: configuration, simulatorID: simulator.id, folder: folder)
            phase = .running("Building \(scheme)…")
            if options.fast == false {
                _ = try await runXcodebuild(request, action: "clean")
            }
            let builtAppPath = try await runXcodebuild(request, action: "build")
            statusText = "Locating the built app…"
            let located = try await provider.locateApp(request, outputPath: builtAppPath)
            let bundle = try await provider.bundleID(appPath: located)
            detectedBundleID = bundle
            session.setLastAppPath(located)
            try? await provider.cacheApp(located, simulatorID: simulator.id, bundleID: bundle)
            await installAndLaunch(mode: mode, simulator: simulator, appPath: located, bundleID: bundle, container: container)
        } catch is CancellationError {
            phase = .idle
        } catch {
            let log = try? await provider.writeLog([error.localizedDescription])
            fail(error.localizedDescription, logPath: log)
        }
    }

    private func runXcodebuild(_ request: BuildRequest, action: String) async throws -> String? {
        var lastError: String?
        var appPath: String?
        for try await output in provider.xcodebuild(request, action: action) {
            try Task.checkCancellation()
            switch output {
            case let .line(line):
                if let step = XcodeBuildOutput.step(for: line) {
                    phase = .running(step)
                    statusText = step
                }
                if let message = XcodeBuildOutput.errorMessage(in: line) {
                    lastError = message
                }
                if let found = XcodeBuildOutput.appPath(in: line, configuration: request.configuration) {
                    appPath = found
                }
            case let .finished(code):
                guard code == 0 else {
                    throw BuildError(message: lastError ?? "xcodebuild \(action) exited with code \(code).")
                }
            }
        }
        return appPath
    }

    private func launchOnly(mode: RunMode, simulator: SimulatorInfo, container: String) async {
        guard let bundleID else {
            fail("Build once first so DevHub knows the bundle ID.")
            return
        }
        let installed = await simulatorProvider.isInstalled(simulatorID: simulator.id, bundleID: bundleID)
        guard installed else {
            fail("\(bundleID) is not installed on \(simulator.name). Build & Run first.")
            return
        }
        await launch(mode: mode, simulator: simulator, bundleID: bundleID, container: container)
    }

    private func installAndLaunch(mode: RunMode, simulator: SimulatorInfo, appPath: String, bundleID: String, container: String) async {
        statusText = "Installing…"
        phase = .running("Installing…")
        do {
            if options.cleanInstall {
                try? await simulatorProvider.uninstall(simulatorID: simulator.id, bundleID: bundleID)
            }
            try await simulatorProvider.install(simulatorID: simulator.id, appPath: appPath)
        } catch {
            fail(error.localizedDescription)
            return
        }
        await launch(mode: mode, simulator: simulator, bundleID: bundleID, container: container)
    }

    private func launch(mode: RunMode, simulator: SimulatorInfo, bundleID: String, container: String) async {
        let message = mode.waitsForDebugger ? "Launching and waiting for the debugger…" : "Launching…"
        statusText = message
        phase = .running(message)
        do {
            if let defaults = profile?.defaults, defaults.isEmpty == false {
                try await simulatorProvider.writeDefaults(simulatorID: simulator.id, bundleID: bundleID, defaults: defaults)
            }
            await simulatorProvider.terminate(simulatorID: simulator.id, bundleID: bundleID)
            let request = LaunchRequest(
                simulatorID: simulator.id,
                bundleID: bundleID,
                arguments: profile?.args ?? [],
                environment: profile?.env ?? [:],
                waitsForDebugger: mode.waitsForDebugger
            )
            let processID = try await simulatorProvider.launch(request)
            phase = .succeeded("\(bundleID) launched on \(simulator.name).")
            if mode.waitsForDebugger, let processID {
                await attach(processID: processID, simulator: simulator, container: container)
            }
        } catch {
            fail(error.localizedDescription)
        }
    }

    private func attach(processID: Int, simulator: SimulatorInfo, container: String) async {
        guard debugger.isTrusted() else {
            attachNotice = AttachNotice(
                message: AttachAdvice.accessMessage,
                steps: AttachAdvice.manualSteps(processID: processID),
                canRequestAccess: true
            )
            return
        }
        let request = AttachRequest(processID: processID, simulatorID: simulator.id, container: container)
        do {
            try await debugger.attach(request) { [weak self] step in
                Task { @MainActor [weak self] in
                    self?.statusText = step
                }
            }
        } catch {
            attachNotice = AttachNotice(
                message: error.localizedDescription,
                steps: AttachAdvice.manualSteps(processID: processID),
                canRequestAccess: false
            )
        }
    }

    private func runCommand(mode: RunMode, simulator: SimulatorInfo, folder: String) async {
        guard mode != .launch else {
            fail("Command projects always rebuild. Use Build & Run.")
            return
        }
        guard let buildCommand = config.config.build?.command, let resolved = config.resolveScript(buildCommand) else {
            fail("Set build.command in the .devhub config for this command project.")
            return
        }
        let context = ActionContextBuilder(session: session, config: config).make(
            configDir: (resolved as NSString).deletingLastPathComponent,
            item: ActionItemContext(simulatorUDID: simulator.id, simulatorName: simulator.name),
            inputs: [:]
        )
        phase = .running("Running \(buildCommand)…")
        do {
            try await stream(resolved, folder: folder, environment: context.environment)
        } catch is CancellationError {
            phase = .idle
            return
        } catch {
            let log = try? await provider.writeLog([error.localizedDescription])
            fail(error.localizedDescription, logPath: log)
            return
        }
        if let runCommand = config.config.run?.command, let resolvedRun = config.resolveScript(runCommand) {
            phase = .running("Running \(runCommand)…")
            do {
                try await stream(resolvedRun, folder: folder, environment: context.environment)
            } catch is CancellationError {
                phase = .idle
                return
            } catch {
                fail(error.localizedDescription)
                return
            }
        }
        phase = .succeeded("\(config.effective?.name ?? "The command") finished.")
    }

    private func stream(_ executable: String, folder: String, environment: [String: String]) async throws {
        for try await output in provider.command(executable: executable, folder: folder, environment: environment) {
            try Task.checkCancellation()
            switch output {
            case let .line(line):
                statusText = line
                phase = .running(line)
            case let .finished(code):
                guard code == 0 else {
                    throw BuildError(message: "\(executable) exited with code \(code).")
                }
            }
        }
    }
}
