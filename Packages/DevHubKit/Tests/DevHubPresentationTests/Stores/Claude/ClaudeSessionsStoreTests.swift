import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct ClaudeSessionsStoreTests {
    private let harness = StoreHarness()

    private var store: ClaudeSessionsStore {
        harness.claudeSessions
    }

    @Test func scopeDefaultsToTheProject() {
        #expect(store.scope == .project)
    }

    @Test func scopeIsRestoredFromTheStore() {
        let saved = InMemoryKeyValueStore()
        saved.set("All", forKey: "claude.scope")

        #expect(StoreHarness(store: saved).claudeSessions.scope == .all)
    }

    @Test func scopeIsWrittenOnChange() {
        store.scope = .all

        #expect(harness.store.string(forKey: "claude.scope") == "All")
    }

    @Test func refreshLoadsTheSessions() async {
        harness.spies.claudeSessions.sessionsResult = ClaudeSessionSample.all
        #expect(store.hasLoaded == false)

        await store.refresh()

        #expect(store.sessions == ClaudeSessionSample.all)
        #expect(store.hasLoaded)
        #expect(store.isLoading == false)
        #expect(harness.spies.claudeSessions.calls == [.sessions])
    }

    @Test func projectScopeKeepsSessionsInsideTheProjectFolder() async {
        harness.spies.claudeSessions.sessionsResult = ClaudeSessionSample.all
        await store.refresh()

        #expect(store.scoped == [ClaudeSessionSample.root, ClaudeSessionSample.nested])

        store.scope = .all

        #expect(store.scoped == ClaudeSessionSample.all)
    }
}
