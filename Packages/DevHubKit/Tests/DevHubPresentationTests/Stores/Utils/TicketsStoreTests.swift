import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct TicketsStoreTests {
    private let harness = StoreHarness()

    private var store: TicketsStore {
        harness.tickets
    }

    private var spy: SpyIssueTrackerRepository {
        harness.spies.tracker
    }

    private let issue = TrackerIssue(key: "ABC-123", summary: "Login button stays disabled", status: "To Do", statusCategory: .toDo, type: "Bug", priority: "High", assignee: "Alex", url: nil, updatedAt: nil)

    // MARK: Refresh

    @Test func withoutATrackerNothingIsRead() async {
        await store.refresh()

        #expect(store.isEnabled == false)
        #expect(store.issues.isEmpty)
        #expect(spy.calls.isEmpty)
    }

    @Test func refreshChecksTheToolThenReadsTheTicketsOfTheUser() async {
        await enableTracker()
        spy.issuesResult = .success([issue])

        await store.refresh()

        #expect(store.toolState == .ready(version: "1.7.0", user: "alex@example.com"))
        #expect(store.issues == [issue])
        #expect(store.error == nil)
        #expect(spy.calls == [.toolState, .issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", limit: 50)])
    }

    @Test func aToolThatIsNotReadyStopsTheRead() async {
        await enableTracker()
        spy.toolStateResult = .notLoggedIn

        await store.refresh()

        #expect(store.toolState == .notLoggedIn)
        #expect(store.isReady == false)
        #expect(spy.calls == [.toolState])
    }

    @Test func aFailedReadKeepsTheMessageAndLogsIt() async {
        await enableTracker()
        spy.issuesResult = .failure(TrackerError.command("Error: invalid JQL"))

        await store.refresh()

        #expect(store.error == "Error: invalid JQL")
        #expect(harness.lastActivity?.title == "Cannot read tickets")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func theScopeIsSavedAndReadsAgain() async throws {
        await enableTracker()
        await store.refresh()

        store.scope = .project

        #expect(harness.store.string(forKey: "utils.tickets.scope") == "project")
        try await waitUntil { spy.calls.contains(.issues(jql: "statusCategory != Done", project: "ABC", limit: 50)) }
    }

    @Test func aSavedScopeIsRead() {
        let store = InMemoryKeyValueStore()
        store.set("project", forKey: "utils.tickets.scope")

        #expect(StoreHarness(store: store).tickets.scope == .project)
    }

    @Test func aProjectChangeDropsTheList() async {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()

        harness.events.post(.projectChanged)

        #expect(store.issues.isEmpty)
    }

    // MARK: Move

    @Test func aMoveTransitionsLogsAndReadsAgain() async throws {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()

        store.move("ABC-123", to: "In Review")

        #expect(store.busyKeys == ["ABC-123"])
        try await waitUntil { store.busyKeys.isEmpty && spy.calls.count == 5 }
        #expect(spy.calls.suffix(3) == [.transition(key: "ABC-123", status: "In Review"), .toolState, .issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", limit: 50)])
        #expect(harness.lastActivity?.title == "Moved ABC-123 to In Review")
        #expect(harness.lastActivity?.detail == "jira issue move ABC-123 \"In Review\"")
    }

    @Test func startMovesToTheStartStatus() async throws {
        await enableTracker()

        store.start("ABC-123")

        try await waitUntil { spy.calls.contains(.transition(key: "ABC-123", status: "In Progress")) }
    }

    @Test func aFailedMoveIsLoggedAndShown() async throws {
        await enableTracker()
        spy.transitionError = TrackerError.command("Error: invalid transition state")

        store.move("ABC-123", to: "Nowhere")

        try await waitUntil { store.busyKeys.isEmpty }
        #expect(harness.lastActivity?.title == "Could not move ABC-123 to Nowhere")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(spy.calls.contains(.issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", limit: 50)) == false)
    }

    @Test func theBranchNameFollowsTheConfiguredFormat() async {
        await enableTracker()

        #expect(store.branchName(for: issue) == "feature/ABC-123-login-button-stays-disabled")
    }

    private func enableTracker() async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(tracker: TrackerConfig(kind: .jira, project: "ABC")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
    }
}
