import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct BuildStoreTests {
    private let harness = StoreHarness()
    private let simulator = SimulatorSample.shutdown
    private let product = BuildProduct(appPath: "/tmp/DevHubTests/App.app", bundleID: "com.example.app")

    init() {
        harness.simulators.groups = SimulatorSample.shutdownOnly
        harness.spies.build.locateProductResult = .success(product)
    }

    private var store: BuildStore {
        harness.build
    }

    private var savedRunOptions: [String: SimulatorRunOptions]? {
        harness.store.decode([String: SimulatorRunOptions].self, forKey: "simulators.runOptions")
    }

    private var hasFinished: Bool {
        harness.postedLabels.contains { $0.hasPrefix("buildFinished") }
    }

    private func request(path: String, attachDebugger: Bool, launchesApp: Bool = true) -> BuildRequest {
        BuildRequest(
            projectPath: path,
            container: nil,
            scheme: "App",
            configuration: "Debug",
            incremental: true,
            simulatorUDID: simulator.id,
            simulatorName: simulator.name,
            cleanInstall: false,
            launch: .none,
            attachDebugger: attachDebugger,
            launchesApp: launchesApp
        )
    }

    // MARK: Persistence

    @Test func defaultsComeFromTheProject() {
        #expect(store.state.scheme == "App")
        #expect(store.state.configuration == "Debug")
        #expect(store.state.targetSimulatorID == nil)
        #expect(store.source == .main)
        #expect(store.target == simulator)
    }

    @Test func targetAndRunOptionsAreRestored() {
        let saved = InMemoryKeyValueStore()
        let options = SimulatorRunOptions(scheme: "Saved", configuration: "Release", incremental: false, cleanInstall: true, source: .branch("feature/x"), profileID: nil)
        saved.set(simulator.id, forKey: "simulators.target")
        saved.encode([simulator.id: options], forKey: "simulators.runOptions")

        let store = StoreHarness(store: saved).build

        #expect(store.state.targetSimulatorID == simulator.id)
        #expect(store.state.scheme == "Saved")
        #expect(store.state.configuration == "Release")
        #expect(store.state.incremental == false)
        #expect(store.state.cleanInstall)
        #expect(store.source == .branch("feature/x"))
    }

    @Test func optionsAreWrittenForTheSelectedTarget() {
        store.selectTarget(id: simulator.id)
        store.setScheme("Other")
        store.setConfiguration("Release")
        store.setIncremental(false)
        store.setCleanInstall(true)

        #expect(harness.store.string(forKey: "simulators.target") == simulator.id)
        #expect(savedRunOptions == [simulator.id: SimulatorRunOptions(scheme: "Other", configuration: "Release", incremental: false, cleanInstall: true, source: .main, profileID: nil)])
        #expect(store.willCleanInstall(on: simulator.id))
    }

    @Test func optionsAreNotWrittenWithoutATarget() {
        store.setScheme("Other")

        #expect(store.state.scheme == "Other")
        #expect(harness.store.data(forKey: "simulators.runOptions") == nil)
    }

    @Test func selectTargetLoadsThatTargetsOptions() {
        let saved = InMemoryKeyValueStore()
        let options = SimulatorRunOptions(scheme: "App", configuration: "Release", incremental: true, cleanInstall: false, source: .main, profileID: nil)
        saved.encode([SimulatorSample.booted.id: options], forKey: "simulators.runOptions")
        let harness = StoreHarness(store: saved)
        harness.simulators.groups = SimulatorSample.groups

        harness.build.selectTarget(id: SimulatorSample.booted.id)

        #expect(harness.build.state.configuration == "Release")
        #expect(harness.build.target == SimulatorSample.booted)
        #expect(harness.build.isTarget(SimulatorSample.booted.id))
    }

    @Test func targetFallsBackToABootedSimulator() {
        harness.simulators.groups = SimulatorSample.groups

        #expect(store.target == SimulatorSample.booted)

        store.selectTarget(id: SimulatorSample.pad.id)

        #expect(store.target == SimulatorSample.pad)
    }

    // MARK: Source

    @Test func useSourcePicksALinkedWorktree() {
        harness.worktrees.worktrees = [WorktreeSample.main, WorktreeSample.feature]

        store.useSource(worktreeID: WorktreeSample.feature.id)

        #expect(store.source == .worktree(WorktreeSample.feature.path))
        #expect(store.sourceWorktreeID == WorktreeSample.feature.id)
        #expect(store.sourcePath == WorktreeSample.feature.path)
        #expect(store.sourceLabel == "feature/login")
    }

    @Test func useSourceWithTheMainWorktreeUsesMain() {
        harness.worktrees.worktrees = [WorktreeSample.main, WorktreeSample.feature]

        store.useSource(worktreeID: WorktreeSample.main.id)

        #expect(store.source == .main)
        #expect(store.sourcePath == WorktreeSample.main.path)
        #expect(store.sourceLabel == "dev · main checkout")
    }

    @Test func useSourceBranchPrefersAnExistingWorktree() {
        harness.worktrees.worktrees = [WorktreeSample.main, WorktreeSample.feature]

        store.useSource(branch: "origin/feature/login")

        #expect(store.source == .worktree(WorktreeSample.feature.path))
    }

    @Test func useSourceBranchWithoutAWorktreeWaitsForTheRun() {
        store.useSource(branch: "origin/feature/new")

        #expect(store.source == .branch("feature/new"))
        #expect(store.sourcePath == ProjectSample.path)
        #expect(store.sourceLabel == "feature/new · new worktree on run")
    }

    // MARK: Events

    @Test func projectChangedResetsTheSourceAndRefreshesSchemes() async throws {
        harness.spies.build.schemesResult = ["App", "AppTests"]
        store.useSource(branch: "feature/new")

        harness.events.post(.projectChanged)

        #expect(store.source == .main)
        try await waitUntil { store.schemes == ["App", "AppTests"] }
        #expect(harness.spies.build.calls.contains(.schemes(projectPath: ProjectSample.path)))
        #expect(store.state.scheme == "App")
        #expect(store.schemeOptions == ["App", "AppTests"])
    }

    @Test func refreshSchemesReplacesAMissingScheme() async {
        harness.spies.build.schemesResult = ["App", "AppTests"]
        store.setScheme("Gone")

        await store.refreshSchemes()

        #expect(store.state.scheme == "App")
    }

    @Test func schemeOptionsFallBackToTheCurrentScheme() {
        #expect(store.schemeOptions == ["App"])
    }

    @Test func worktreesChangedDropsAMissingWorktreeSource() {
        harness.worktrees.worktrees = [WorktreeSample.main, WorktreeSample.feature]
        store.useSource(worktreeID: WorktreeSample.feature.id)
        harness.worktrees.worktrees = [WorktreeSample.main]

        harness.events.post(.worktreesChanged)

        #expect(store.source == .main)
    }

    // MARK: Run

    @Test func runBuildsInstallsAndLaunches() async throws {
        harness.spies.build.buildEvents = [.step("Compiling", progress: 0.5), .output("line 1")]

        store.run()

        #expect(store.state.phase == .running(step: "Preparing", progress: nil))
        #expect(store.isRunning)
        #expect(harness.postedLabels.first == "buildStarted(sim-off)")
        #expect(harness.store.string(forKey: "simulators.target") == simulator.id)
        try await waitUntil { hasFinished }
        guard case .succeeded = store.state.phase else {
            Issue.record("Expected a succeeded phase, got \(store.state.phase)")
            return
        }
        #expect(store.log == ["line 1", "App: \(product.appPath)"])
        #expect(harness.postedLabels.contains("buildFinished(sim-off, - -)"))
        #expect(harness.spies.build.calls == [
            .build(request(path: ProjectSample.path, attachDebugger: false)),
            .locateProduct(request(path: ProjectSample.path, attachDebugger: false), hints: []),
        ])
        #expect(harness.spies.simulators.calls.prefix(5) == [
            .boot(udid: simulator.id),
            .waitUntilBooted(udid: simulator.id),
            .install(udid: simulator.id, appPath: product.appPath),
            .openInSimulatorApp(udid: simulator.id),
            .launch(udid: simulator.id, bundleID: product.bundleID, waitForDebugger: false, environment: [:]),
        ])
        #expect(harness.lastActivity?.title == "Launched App")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func hasLogIsSetByTheFirstOutputLineAndResetByTheNextRun() async throws {
        harness.spies.build.buildEvents = [.output("line 1")]
        #expect(store.hasLog == false)

        store.run()

        #expect(store.hasLog == false)
        try await waitUntil { hasFinished }
        #expect(store.hasLog)
    }

    @Test func aSecondRunWhileRunningIsIgnored() async throws {
        store.run()
        store.run()

        try await waitUntil { hasFinished }
        #expect(harness.postCount("buildStarted(sim-off)") == 1)
        #expect(harness.spies.build.calls.filter { if case .build = $0 { true } else { false } }.count == 1)
    }

    @Test func runWithoutASimulatorDoesNothing() {
        harness.simulators.groups = []

        store.run()

        #expect(store.isRunning == false)
        #expect(harness.postedLabels.isEmpty)
    }

    @Test func aBuildErrorFailsTheRun() async throws {
        harness.spies.build.buildError = BuildError.failed("Compile error")

        store.run()

        try await waitUntil { hasFinished }
        #expect(store.state.phase == .failed("Compile error"))
        #expect(harness.lastActivity?.title == "Build failed")
        #expect(harness.lastActivity?.detail == "Compile error")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aFailedBuildWhileThePanelIsClosedNotifiesAndMarksTheIcon() async throws {
        harness.spies.build.buildError = BuildError.failed("Compile error")

        store.run()

        try await waitUntil { hasFinished }
        #expect(harness.notifier.hasUnseenFailure)
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Build failed: App", body: "Compile error", target: .build)] }
    }

    @Test func cancelReturnsToIdle() async throws {
        store.run()
        store.cancel()

        try await waitUntil { hasFinished }
        #expect(store.state.phase == .idle)
        #expect(harness.lastActivity?.title == "Build cancelled")
        #expect(harness.lastActivity?.outcome == .info)
        #expect(harness.postedLabels.contains("buildFinished(sim-off, none)"))
        #expect(harness.spies.build.calls.isEmpty)
    }

    @Test func runAndAttachAttachesXcode() async throws {
        harness.spies.simulators.launchResult = .success(42)

        store.runAndAttach()

        try await waitUntil { hasFinished }
        #expect(harness.spies.build.calls.first == .build(request(path: ProjectSample.path, attachDebugger: true)))
        #expect(harness.spies.attacher.calls == [.attach(pid: 42, simulatorUDID: simulator.id, projectPath: ProjectSample.path, container: nil)])
        #expect(harness.lastActivity?.title == "Launched App, Xcode attached")
    }

    @Test func runAndAttachAsksForAccessibilityFirst() {
        harness.spies.attacher.isTrusted = false

        store.runAndAttach()

        #expect(store.isRunning == false)
        #expect(harness.spies.attacher.calls == [.requestTrust])
        #expect(harness.lastActivity?.title == "Allow DevHub in Accessibility")
    }

    @Test func buildOnlyBuildsWithoutAnInstallOrALaunch() async throws {
        store.buildOnly()

        #expect(store.isRunning)
        try await waitUntil { hasFinished }
        guard case .succeeded(_, let launched) = store.state.phase else {
            Issue.record("Expected a succeeded phase, got \(store.state.phase)")
            return
        }
        #expect(launched == false)
        #expect(store.log == ["App: \(product.appPath)"])
        #expect(harness.spies.build.calls == [
            .build(request(path: ProjectSample.path, attachDebugger: false, launchesApp: false)),
            .locateProduct(request(path: ProjectSample.path, attachDebugger: false, launchesApp: false), hints: []),
        ])
        #expect(harness.spies.simulators.calls.first == .boot(udid: simulator.id))
        #expect(harness.spies.simulators.calls.contains(.install(udid: simulator.id, appPath: product.appPath)) == false)
        #expect(harness.spies.simulators.calls.contains { if case .launch = $0 { true } else { false } } == false)
        #expect(harness.postedLabels.contains("buildFinished(sim-off, none)"))
        #expect(harness.lastActivity?.title == "Built App")
        #expect(harness.lastActivity?.outcome == .success)
        try await waitUntil { harness.spies.notifications.posted.count == 1 }
        #expect(harness.spies.notifications.posted.first == .post(title: "Built App", body: "Debug · \(ProjectSample.path.abbreviatingHome)", target: .build))
    }

    @Test func runBranchCreatesAWorktreeFirst() async throws {
        harness.spies.worktrees.createResult = .success(NewWorktree(path: WorktreeSample.created.path, branch: "feature/created"))
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.created])

        store.run(branch: "origin/feature/created")

        try await waitUntil { hasFinished }
        #expect(harness.spies.worktrees.calls.prefix(2) == [
            .create(branch: "feature/created", base: "origin/main", projectPath: ProjectSample.path),
            .list(projectPath: ProjectSample.path),
        ])
        #expect(harness.postedLabels.contains("worktreeCheckoutPrepared"))
        #expect(harness.activityTitles.contains("Created worktree"))
        #expect(harness.spies.build.calls.first == .build(request(path: WorktreeSample.created.path, attachDebugger: false)))
    }

    @Test func aFailedWorktreeCreationFailsTheRun() async throws {
        harness.spies.worktrees.createResult = .failure(TestError.scripted("exists"))

        store.run(branch: "feature/created")

        try await waitUntil { hasFinished }
        #expect(Array(harness.activityTitles.prefix(2)) == ["Build failed", "Could not create worktree"])
        guard case .failed = store.state.phase else {
            Issue.record("Expected a failed phase, got \(store.state.phase)")
            return
        }
    }

    @Test func runWorktreeBuildsThatCheckout() async throws {
        harness.worktrees.worktrees = [WorktreeSample.main, WorktreeSample.feature]

        store.run(worktreeID: WorktreeSample.feature.id)

        try await waitUntil { hasFinished }
        #expect(store.source == .worktree(WorktreeSample.feature.path))
        #expect(harness.spies.build.calls.first == .build(request(path: WorktreeSample.feature.path, attachDebugger: false)))
    }

    @Test func runWithAnIdentityReportsTheLaunch() async throws {
        harness.spies.config.loadResult = LaunchConfigSample.resolved()
        await harness.config.reload()
        harness.simulators.groups = SimulatorSample.shutdownOnly
        harness.spies.build.locateProductResult = .success(product)
        harness.identity.setDesiredDeviceID("device-1", for: simulator.id)

        store.run()

        try await waitUntil { harness.postedLabels.contains("buildFinished(sim-off, staging device-1)") }
        #expect(harness.spies.simulators.calls.contains(.launch(udid: simulator.id, bundleID: product.bundleID, waitForDebugger: false, environment: ["API_ENV": "staging", "APP_DEVICE_ID": "device-1"])))
        #expect(harness.identity.savedDeviceIDs == ["device-1"])
        #expect(harness.identity.settings(for: simulator.id).appliedIdentity == "device-1")
        #expect(harness.identity.settings(for: simulator.id).lastLaunch?.profileID == "staging")
    }

    @Test func lastBuiltAppPathAsksForTheSource() {
        harness.spies.build.lastBuiltAppPathResult = product.appPath

        #expect(store.lastBuiltAppPath() == product.appPath)
        #expect(harness.spies.build.calls == [.lastBuiltAppPath(projectPath: ProjectSample.path, scheme: "App", configuration: "Debug")])
    }

    @Test func theProjectConfigChoosesTheSchemesTheConfigurationAndTheContainer() async throws {
        harness.spies.build.schemesResult = ["App", "AppTests", "Tools"]
        let xcode = XcodeConfig(container: "App.xcworkspace", scheme: "Tools", configuration: "Release", schemes: ["Tools", "App"])
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(xcode: xcode), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()

        await store.refreshSchemes()

        #expect(store.schemeOptions == ["Tools", "App"])
        #expect(store.state.scheme == "Tools")
        #expect(store.state.configuration == "Release")
        store.run()
        try await waitUntil { hasFinished }
        let build = harness.spies.build.calls.first { if case .build = $0 { true } else { false } }
        guard case .build(let request) = build else {
            Issue.record("Expected a build call")
            return
        }
        #expect(request.container == "App.xcworkspace")
        #expect(request.scheme == "Tools")
        #expect(request.configuration == "Release")
    }

    @Test func theChosenLaunchProfileRunsAndIsSavedPerSimulator() async throws {
        let staging = LaunchProfile(id: "staging", title: "Staging", env: ["API_ENV": "staging"], args: ["-Debug"])
        let production = LaunchProfile(id: "production", title: "Production", cleanInstall: true)
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(launch: LaunchConfig(profiles: [staging, production])), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
        #expect(store.profile == staging)

        store.selectTarget(id: simulator.id)
        store.setProfile("production")
        store.run()
        try await waitUntil { hasFinished }

        #expect(savedRunOptions?[simulator.id]?.profileID == "production")
        let build = harness.spies.build.calls.first { if case .build = $0 { true } else { false } }
        guard case .build(let request) = build else {
            Issue.record("Expected a build call")
            return
        }
        #expect(request.cleanInstall)
        #expect(request.launch == LaunchPlan(profile: production, identityConfig: nil, identity: nil, baseURLVariable: nil))
    }

    @Test func aCommandProjectRunsItsCommandsInsteadOfXcodebuild() async throws {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(kind: .command, build: CommandConfig(command: "scripts/build.sh"), run: CommandConfig(command: "scripts/run.sh")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
        #expect(store.commandsSummary == "scripts/build.sh → scripts/run.sh")

        store.runAndAttach()
        #expect(store.isRunning == false)
        #expect(harness.lastActivity?.title == "Run & Attach needs an Xcode project")

        store.run()
        try await waitUntil { hasFinished }

        #expect(harness.spies.scripts.calls.map(\.executable) == [ProjectSample.path + "/scripts/build.sh", ProjectSample.path + "/scripts/run.sh"])
        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_SIMULATOR_UDID"] == simulator.id)
        #expect(harness.spies.build.calls.contains { if case .build = $0 { true } else { false } } == false)
    }

    @Test func issuesAreCollectedOnceAndResetByTheNextRun() async throws {
        let issue = BuildIssue(severity: .error, path: "/a.swift", line: 1, column: 2, message: "boom")
        harness.spies.build.buildEvents = [.issue(issue), .issue(issue)]

        store.run()
        try await waitUntil { hasFinished }

        #expect(store.issues == [issue])
    }

    @Test func writeFixPromptSavesTheErrorsOfTheLastBuild() async throws {
        let issue = BuildIssue(severity: .error, path: "/a.swift", line: 1, column: 2, message: "boom")
        harness.spies.build.buildEvents = [.issue(issue)]
        harness.spies.reviewPrompts.saveResult = .success("/tmp/prompts/fix-build-app.md")
        store.run()
        try await waitUntil { hasFinished }

        let path = await store.writeFixPrompt()

        #expect(path == "/tmp/prompts/fix-build-app.md")
        let prompt = try #require(harness.spies.reviewPrompts.savedPrompts.first)
        #expect(prompt.hasPrefix("# Build errors of App in"))
        #expect(prompt.contains("- `/a.swift:1`: boom"))
        #expect(harness.spies.reviewPrompts.calls.first == .saveNamed(prompt, name: "fix-build-app"))
    }

    @Test func writeFixPromptWithoutErrorsSaysNothingToFix() async {
        let path = await store.writeFixPrompt()

        #expect(path == nil)
        #expect(harness.lastActivity?.title == "Nothing to fix")
        #expect(harness.spies.reviewPrompts.calls.isEmpty)
    }

    // MARK: Manual schemes

    @Test func addedSchemeJoinsTheOptionsAndIsSelected() {
        store.addScheme(" Tools ")

        #expect(store.manualSchemes == ["Tools"])
        #expect(store.schemeOptions == ["App", "Tools"])
        #expect(store.state.scheme == "Tools")
        #expect(harness.store.decode([String].self, forKey: "build.manualSchemes.\(ProjectSample.app.id)") == ["Tools"])
    }

    @Test func addingAVisibleSchemeChangesNothing() async {
        harness.spies.build.schemesResult = ["App", "AppTests"]
        await store.refreshSchemes()

        store.addScheme("AppTests")

        #expect(store.manualSchemes.isEmpty)
        #expect(store.state.scheme == "App")
    }

    @Test func removingTheSelectedSchemeFallsBackToTheProjectScheme() {
        store.addScheme("Tools")

        store.removeScheme("Tools")

        #expect(store.manualSchemes.isEmpty)
        #expect(store.state.scheme == "App")
        #expect(harness.store.decode([String].self, forKey: "build.manualSchemes.\(ProjectSample.app.id)") == nil)
    }

    @Test func refreshKeepsASelectedManualScheme() async {
        harness.spies.build.schemesResult = ["App", "AppTests"]
        store.addScheme("Tools")

        await store.refreshSchemes()

        #expect(store.state.scheme == "Tools")
    }

    @Test func manualSchemesBelongToTheProject() {
        store.addScheme("Tools")

        harness.session.selectedProjectID = ProjectSample.other.id

        #expect(store.manualSchemes.isEmpty)

        harness.session.selectedProjectID = ProjectSample.app.id

        #expect(store.manualSchemes == ["Tools"])
    }

    @Test func suggestionsComeFromTheProjectList() async {
        harness.spies.build.listedSchemesResult = .success(["App", "Tools", "Widget"])
        store.addScheme("Tools")

        await store.loadSchemeSuggestions()

        #expect(harness.spies.build.calls.contains(.listedSchemes(projectPath: ProjectSample.path)))
        #expect(store.newSchemeSuggestions == ["Widget"])
        #expect(store.isLoadingSchemeSuggestions == false)
    }

    @Test func failedSuggestionsAreLogged() async {
        harness.spies.build.listedSchemesResult = .failure(TestError.scripted("xcodebuild failed"))

        await store.loadSchemeSuggestions()

        #expect(store.schemeSuggestions == [])
        #expect(harness.lastActivity?.outcome == .failure)
    }
}
