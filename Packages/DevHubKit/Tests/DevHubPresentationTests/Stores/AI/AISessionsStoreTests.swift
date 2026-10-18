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
}
