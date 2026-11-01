import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct ConfigActionsStoreTests {
    private let harness = StoreHarness()

    private var store: ConfigActionsStore {
        harness.configActions
    }

    private func load(_ actions: [ResolvedAction]) async {
        harness.spies.config.loadResult = ConfigSample.resolved(actions)
        await harness.config.reload()
    }

    private func finish(_ id: String) async throws {
        try await waitUntil { store.isRunning(id) == false && store.runs[id] != nil }
    }

    @Test func aScriptRunsWithTheContextEnvironment() async throws {
        let action = ConfigSample.action("clean")
        await load([action])

        store.request(action, item: ActionItemContext(branch: "feature/ABC-1"), slot: "home.scripts:clean")
        try await finish("clean")

        let request = try #require(harness.spies.scripts.calls.first)
        #expect(request.executable == ConfigSample.directory + "/scripts/run.sh")
        #expect(request.environment["DEVHUB_BRANCH"] == "feature/ABC-1")
        #expect(request.environment["DEVHUB_PROJECT_PATH"] == ProjectSample.path)
        #expect(request.environment["DEVHUB_VERSION"] == "1.0")
        #expect(store.runs["clean"]?.status == .succeeded)
        #expect(harness.lastActivity?.outcome == .success)
        #expect(store.lastRun(of: "clean") != nil)
    }

    @Test func aRowSimulatorGetsTheContainersOfTheApp() async throws {
        let action = ConfigSample.action("clean")
        harness.spies.launcher.containersResult = AppContainers(app: "/sim/Bundle/App.app", data: "/sim/Data/App")
        await load([action])

        store.request(action, item: ActionItemContext(simulatorUDID: "SIM-1"), slot: "network.toolbar")
        try await finish("clean")

        let request = try #require(harness.spies.scripts.calls.first)
        #expect(request.environment["DEVHUB_APP_CONTAINER"] == "/sim/Bundle/App.app")
        #expect(request.environment["DEVHUB_DATA_CONTAINER"] == "/sim/Data/App")
        #expect(request.environment["DEVHUB_PROFILE"] == "")
        #expect(harness.spies.launcher.calls.contains { if case .containers(udid: "SIM-1", bundleID: _) = $0 { true } else { false } })
    }

    @Test func aRowSimulatorGetsItsStateAndTheGroupContainers() async throws {
        harness.simulators.groups = SimulatorSample.groups
        harness.spies.launcher.containersResult = AppContainers(app: "", data: "/sim/Data/App", groups: [AppDataFile(name: "group.com.example.app", path: "/sim/Shared/A", size: 0)])
        let action = ConfigSample.action("clean")
        await load([action])

        store.request(action, item: ActionItemContext(simulatorUDID: SimulatorSample.booted.id), slot: "s")
        try await finish("clean")

        let request = try #require(harness.spies.scripts.calls.first)
        #expect(request.environment["DEVHUB_SIMULATOR_STATE"] == "booted")
        #expect(request.environment["DEVHUB_GROUP_CONTAINERS"] == "group.com.example.app\t/sim/Shared/A")
    }

    @Test func anItemBundleIDPicksTheContainersOfThatApp() async throws {
        let action = ConfigSample.action("clean")
        await load([action])

        store.request(action, item: ActionItemContext(simulatorUDID: "SIM-1", bundleID: "com.example.app.widget"), slot: "s")
        try await finish("clean")

        #expect(harness.spies.launcher.calls.contains(.containers(udid: "SIM-1", bundleID: "com.example.app.widget")))
        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_BUNDLE_ID"] == "com.example.app.widget")
    }

    @Test func itemRefreshTargetsArePostedAfterAFailure() async throws {
        harness.spies.scripts.events = [.output("boom"), .exited(1)]
        let action = ConfigSample.action("fail")
        await load([action])

        store.request(action, item: ActionItemContext(refresh: [.appData]), slot: "s")
        try await finish("fail")

        #expect(harness.postCount("refreshRequested(appData)") == 1)
    }

    @Test func theBranchFallsBackToTheMainWorktree() async throws {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main])
        await harness.worktrees.refresh()
        let action = ConfigSample.action("branch")
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("branch")

        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_BRANCH"] == WorktreeSample.main.branch)
    }

    @Test func aRowRequestByIDGetsTheRowContext() async throws {
        let action = ConfigSample.action("open", placements: [.worktreesRow])
        await load([action])

        store.request(id: "open", item: ActionItemContext(branch: "feature/ABC-2", worktreePath: "/tmp/wt", rowID: "/tmp/wt"), slot: Placement.worktreesRow.slot(for: "/tmp/wt"))
        try await finish("open")

        let environment = try #require(harness.spies.scripts.calls.first?.environment)
        #expect(environment["DEVHUB_WORKTREE_PATH"] == "/tmp/wt")
        #expect(environment["DEVHUB_ROW_ID"] == "/tmp/wt")
        #expect(environment["DEVHUB_BRANCH"] == "feature/ABC-2")
    }

    @Test func aRowRequestWithInputsOpensThePromptInTheRowSlot() async {
        let action = ConfigSample.action("ask", placements: [.gitBranchRow], confirm: "Sure?")
        await load([action])

        store.request(id: "ask", item: ActionItemContext(branch: "main", rowID: "main"), slot: Placement.gitBranchRow.slot(for: "main"))

        #expect(store.pending(in: "git.branchRow:main")?.action.id == "ask")
        #expect(store.pending(in: "git.branchRow:other") == nil)
        #expect(harness.spies.scripts.calls.isEmpty)
    }

    @Test func aRequestForAnUnknownIDShowsAToast() async {
        await load([])

        store.request(id: "gone", item: .none, slot: "s")

        #expect(harness.toaster.text?.contains("gone") == true)
        #expect(harness.spies.scripts.calls.isEmpty)
    }

    @Test func aCommandExpandsPlaceholders() async throws {
        let action = ConfigSample.action("echo", run: .command(["/bin/echo", "{branch}", "{name}"]), inputs: [ActionInput(key: "name", title: "Name", type: .text, defaultValue: "sam")])
        await load([action])

        store.runWithDefaults(action, item: ActionItemContext(branch: "main"))
        try await finish("echo")

        #expect(harness.spies.scripts.calls.first?.executable == "/bin/echo")
        #expect(harness.spies.scripts.calls.first?.arguments == ["main", "sam"])
        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_INPUT_NAME"] == "sam")
    }

    @Test func inputsAndConfirmOpenAPromptFirst() async throws {
        let action = ConfigSample.action("ask", inputs: [ActionInput(key: "target", title: "Target", type: .choice, options: [InputOption(value: "app"), InputOption(value: "widget")])], confirm: "Sure?")
        await load([action])

        store.request(action, item: .none, slot: "home.scripts:ask")

        #expect(store.pending(in: "home.scripts:ask")?.inputs == ["target": "app"])
        #expect(store.pending(in: "other") == nil)
        #expect(harness.spies.scripts.calls.isEmpty)

        store.setInput("widget", for: "target")
        store.confirmPending()
        try await finish("ask")

        #expect(store.pending == nil)
        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_INPUT_TARGET"] == "widget")
    }

    @Test func cancelPendingRunsNothing() async {
        let action = ConfigSample.action("ask", confirm: "Sure?")
        await load([action])
        store.request(action, item: .none, slot: "s")

        store.cancelPending()

        #expect(store.pending == nil)
        #expect(harness.spies.scripts.calls.isEmpty)
    }

    @Test func rememberedInputsComeBack() async throws {
        let action = ConfigSample.action("ask", inputs: [ActionInput(key: "name", title: "Name", type: .text, defaultValue: "alex", remember: true)])
        await load([action])
        store.request(action, item: .none, slot: "s")
        store.setInput("sam", for: "name")
        store.confirmPending()
        try await finish("ask")

        store.request(action, item: .none, slot: "s")

        #expect(store.pending?.inputs == ["name": "sam"])
    }

    @Test func aScriptWithoutTheExecuteBitDoesNotRun() async {
        let action = ConfigSample.action("blocked", isExecutable: false)
        await load([action])

        store.request(action, item: .none, slot: "s")

        #expect(harness.spies.scripts.calls.isEmpty)
        #expect(harness.toaster.text?.contains("chmod +x") == true)
    }

    @Test func aNonZeroExitFails() async throws {
        harness.spies.scripts.events = [.output("boom"), .exited(2)]
        let action = ConfigSample.action("fail")
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("fail")

        #expect(store.runs["fail"]?.failureMessage == "Exited with code 2.")
        #expect(harness.operations.latest(at: .action("fail"))?.failureMessage == "Exited with code 2.")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postCount("commandFailed") == 0)
    }

    @Test func anErrorDirectiveFailsAndOpensTheOutput() async throws {
        harness.spies.scripts.events = [.output(#"@devhub {"error": "No device"}"#), .exited(0)]
        let action = ConfigSample.action("err")
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("err")

        #expect(store.runs["err"]?.failureMessage == "No device")
        #expect(harness.postCount("commandFailed") == 1)
    }

    @Test func directivesDriveToastCopyProgressAndView() async throws {
        harness.spies.scripts.holdsOpen = true
        harness.spies.scripts.events = [
            .output(#"@devhub {"progress": "Step 1", "fraction": 0.5}"#),
            .output(#"@devhub {"copy": "abc"}"#),
            .output(#"@devhub {"view": {"text": "All good"}}"#),
        ]
        let action = ConfigSample.action("dir")
        await load([action])

        store.request(action, item: .none, slot: "s")

        try await waitUntil { store.runs["dir"]?.view?.text == "All good" }
        #expect(harness.operations.latest(at: .action("dir"))?.progressText == "Step 1")
        #expect(harness.operations.latest(at: .action("dir"))?.fraction == 0.5)
        #expect(harness.copied == ["abc"])
        harness.spies.scripts.finishAll()
        try await finish("dir")
        #expect(harness.operations.latest(at: .action("dir"))?.status == .succeeded)
        #expect(store.runs["dir"]?.view?.text == "All good")
    }

    @Test func aNotifyDirectivePostsANotification() async throws {
        harness.spies.scripts.events = [.output(#"@devhub {"notify": "Done", "body": "Resources ready"}"#), .exited(0)]
        let action = ConfigSample.action("note")
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("note")

        try await waitUntil { harness.spies.notifications.posted == [.post(title: "Done", body: "Resources ready", target: nil)] }
    }

    @Test func refreshPostsTheTargetsAfterSuccess() async throws {
        harness.spies.scripts.events = [.output(#"@devhub {"refresh": ["git"]}"#), .exited(0)]
        let action = ConfigSample.action("ref", refresh: [.worktrees])
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("ref")

        #expect(harness.postCount("refreshRequested(git)") == 1)
        #expect(harness.postCount("refreshRequested(worktrees)") == 1)
    }

    @Test func stopCancelsTheRun() async throws {
        harness.spies.scripts.holdsOpen = true
        let action = ConfigSample.action("long")
        await load([action])
        store.request(action, item: .none, slot: "s")
        try await waitUntil { harness.spies.scripts.calls.count == 1 }

        store.stop("long")
        try await finish("long")

        #expect(store.runs["long"]?.status == .cancelled)
        #expect(harness.operations.latest(at: .action("long"))?.status == .cancelled)
        store.dismissResult(of: "long")
        #expect(store.runs["long"] == nil)
    }

    @Test func retryOfAFailedOperationRunsTheActionAgain() async throws {
        harness.spies.scripts.events = [.output("boom"), .exited(1)]
        let action = ConfigSample.action("again")
        await load([action])
        store.request(action, item: .none, slot: "s")
        try await finish("again")
        let failed = try #require(harness.operations.latest(at: .action("again")))

        harness.operations.retry(failed.id)
        try await waitUntil { harness.spies.scripts.calls.count == 2 }
        try await finish("again")

        #expect(harness.operations.records.filter { $0.origin == .action("again") }.count == 2)
        #expect(harness.operations.record(failed.id)?.isDismissed == true)
    }

    @Test func stopOfTheOperationCancelsTheRun() async throws {
        harness.spies.scripts.holdsOpen = true
        let action = ConfigSample.action("halt")
        await load([action])
        store.request(action, item: .none, slot: "s")
        try await waitUntil { harness.spies.scripts.calls.count == 1 }
        let running = try #require(harness.operations.latest(at: .action("halt")))
        #expect(running.canStop)

        harness.operations.stop(running.id)
        try await finish("halt")

        #expect(harness.operations.record(running.id)?.status == .cancelled)
    }

    @Test func aSecondRunWhileRunningIsIgnored() async throws {
        harness.spies.scripts.holdsOpen = true
        let action = ConfigSample.action("once")
        await load([action])

        store.request(action, item: .none, slot: "s")
        store.request(action, item: .none, slot: "s")
        try await waitUntil { harness.spies.scripts.calls.isEmpty == false }

        #expect(harness.spies.scripts.calls.count == 1)
        harness.spies.scripts.finishAll()
    }

    @Test func actionsForAPlacementFollowTheConfig() async {
        await load([ConfigSample.action("pill", placements: [.gitPills]), ConfigSample.action("home")])

        #expect(store.actions(for: .gitPills).map(\.id) == ["pill"])
        #expect(store.actions(for: .homeScripts).map(\.id) == ["home"])
    }

    @Test func toolConditionsUseTheLocator() async {
        harness.spies.tools.installedTools = ["gh"]
        await load([ConfigSample.action("gh", when: ActionCondition(tool: "gh")), ConfigSample.action("glab", when: ActionCondition(tool: "glab"))])

        #expect(store.actions(for: .homeScripts).map(\.id) == ["gh"])
    }

    @Test func isVisibleChecksTheConditionAndKeepsBuiltins() async {
        harness.spies.tools.installedTools = ["gh"]
        let gh = ConfigSample.action("gh", when: ActionCondition(tool: "gh"))
        let glab = ConfigSample.action("glab", when: ActionCondition(tool: "glab"))
        await load([gh, glab])

        #expect(store.isVisible(.config(gh)))
        #expect(store.isVisible(.config(glab)) == false)
        #expect(store.isVisible(.builtin(.terminal)))
    }
}
