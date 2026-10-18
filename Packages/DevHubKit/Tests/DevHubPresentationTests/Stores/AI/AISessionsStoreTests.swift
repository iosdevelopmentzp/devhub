import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct AISessionsStoreTests {
    private let harness = StoreHarness()

    private var store: AISessionsStore {
        harness.aiSessions
    }

    @Test func scopeDefaultsToTheProject() {
        #expect(store.scope == .project)
    }

    @Test func scopeIsRestoredFromTheStore() {
        let saved = InMemoryKeyValueStore()
        saved.set("All", forKey: "claude.scope")

        #expect(StoreHarness(store: saved).aiSessions.scope == .all)
    }

    @Test func scopeIsWrittenOnChange() {
        store.scope = .all

        #expect(harness.store.string(forKey: "claude.scope") == "All")
    }

    @Test func refreshLoadsTheSessions() async {
        harness.spies.aiSessions.sessionsResult = AISessionSample.all
        #expect(store.hasLoaded == false)

        await store.refresh()

        #expect(store.sessions == AISessionSample.all)
        #expect(store.hasLoaded)
        #expect(store.isLoading == false)
        #expect(harness.spies.aiSessions.calls == [.sessions])
    }

    @Test func projectScopeKeepsSessionsInsideTheProjectFolder() async {
        harness.spies.aiSessions.sessionsResult = AISessionSample.all
        await store.refresh()

        #expect(store.scoped == [AISessionSample.root, AISessionSample.nested])

        store.scope = .all

        #expect(store.scoped == AISessionSample.all)
    }

    @Test func projectScopeAlsoKeepsSessionsInTheWorktrees() async {
        harness.spies.worktrees.listResult = .success([WorktreeSample.main, WorktreeSample.linked(path: AISessionSample.sibling.cwd, branch: "feature/x")])
        await harness.worktrees.refresh()
        harness.spies.aiSessions.sessionsResult = AISessionSample.all
        await store.refresh()

        #expect(store.scoped == [AISessionSample.root, AISessionSample.nested, AISessionSample.sibling])
    }

    @Test func theProviderFilterIsSavedAndFiltersSessions() async {
        var copilot = AISessionSample.session(id: "copilot", cwd: ProjectSample.path)
        copilot.provider = .copilot
        harness.spies.aiSessions.sessionsResult = [AISessionSample.root, copilot]
        await store.refresh()
        #expect(store.providerFilter == .both)
        #expect(store.scoped.map(\.id) == ["root", "copilot"])

        store.providerFilter = .copilot

        #expect(store.scoped.map(\.id) == ["copilot"])
        #expect(harness.store.string(forKey: "ai.provider") == "copilot")
        let saved = InMemoryKeyValueStore()
        saved.set("claude", forKey: "ai.provider")
        #expect(StoreHarness(store: saved).aiSessions.providerFilter == .claude)
    }
}
