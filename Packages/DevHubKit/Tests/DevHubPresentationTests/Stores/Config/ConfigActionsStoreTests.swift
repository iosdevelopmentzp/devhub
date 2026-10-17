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

    @Test func theBranchFallsBackToTheMainWorktree() async throws {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main])
        await harness.worktrees.refresh()
        let action = ConfigSample.action("branch")
        await load([action])

        store.request(action, item: .none, slot: "s")
        try await finish("branch")

        #expect(harness.spies.scripts.calls.first?.environment["DEVHUB_BRANCH"] == WorktreeSample.main.branch)
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
        #expect(store.progress?.text == "Step 1")
        #expect(harness.copied == ["abc"])
        harness.spies.scripts.finishAll()
        try await finish("dir")
        #expect(store.progress == nil)
        #expect(store.runs["dir"]?.view?.text == "All good")
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
        store.dismissResult(of: "long")
        #expect(store.runs["long"] == nil)
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
}
