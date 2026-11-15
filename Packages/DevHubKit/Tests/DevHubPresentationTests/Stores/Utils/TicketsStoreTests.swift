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

    private let details = TrackerIssueDetails(key: "ABC-123", description: "Steps", reporter: "Sam", createdAt: nil, labels: [], components: [], parent: nil, subtasks: [], comments: [])

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
        #expect(spy.calls == [.toolState, .issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", order: .updated, limit: 50)])
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
        try await waitUntil { spy.calls.contains(.issues(jql: "statusCategory != Done", project: "ABC", order: .updated, limit: 50)) }
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
        #expect(spy.calls.suffix(3) == [.transition(key: "ABC-123", status: "In Review"), .toolState, .issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", order: .updated, limit: 50)])
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
        #expect(spy.calls.contains(.issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", order: .updated, limit: 50)) == false)
    }

    // MARK: View

    @Test func theOrderAndTheDoneChoiceAreSavedAndReadAgain() async throws {
        await enableTracker()
        await store.refresh()

        store.order = .priority
        store.includesDone = true

        #expect(harness.store.string(forKey: "utils.tickets.order") == "priority")
        #expect(harness.store.bool(forKey: "utils.tickets.includesDone"))
        try await waitUntil { spy.calls.contains(.issues(jql: "assignee = currentUser() AND (statusCategory != Done OR updated >= -14d)", project: "ABC", order: .priority, limit: 50)) }
        #expect(store.isFiltered)
        #expect(store.isDefaultView == false)
    }

    @Test func theGroupingAndTheHiddenTypesAreSavedAndRead() {
        let saved = InMemoryKeyValueStore()
        saved.set("assignee", forKey: "utils.tickets.grouping")
        saved.set(["Bug"], forKey: "utils.tickets.hiddenTypes")
        saved.set("created", forKey: "utils.tickets.order")
        saved.set(true, forKey: "utils.tickets.includesDone")

        let store = StoreHarness(store: saved).tickets

        #expect(store.grouping == .assignee)
        #expect(store.hiddenTypes == ["Bug"])
        #expect(store.order == .created)
        #expect(store.includesDone)
    }

    @Test func aHiddenTypeHidesItsTicketsAndResetShowsEverything() async {
        await enableTracker()
        let story = TrackerIssue(key: "ABC-124", summary: "Welcome screen", status: "To Do", statusCategory: .toDo, type: "Story", priority: nil, assignee: nil, url: nil, updatedAt: nil)
        spy.issuesResult = .success([issue, story])
        await store.refresh()

        store.toggleType("Bug")
        store.grouping = .type

        #expect(store.types == ["Bug", "Story"])
        #expect(store.isShown(issue) == false)
        #expect(store.isShown(story))
        #expect(harness.store.strings(forKey: "utils.tickets.hiddenTypes") == ["Bug"])
        #expect(harness.store.string(forKey: "utils.tickets.grouping") == "type")

        store.resetView()

        #expect(store.isShown(issue))
        #expect(store.grouping == .status)
        #expect(store.isDefaultView)
    }

    // MARK: Details

    @Test func showingDetailsReadsTheTicketAndHidingKeepsThem() async throws {
        await enableTracker()
        spy.detailsResult = .success(details)

        store.toggleDetails("ABC-123")

        #expect(store.expandedKey == "ABC-123")
        try await waitUntil { store.details["ABC-123"] == details }
        #expect(spy.calls == [.details(key: "ABC-123")])

        store.toggleDetails("ABC-123")

        #expect(store.expandedKey == nil)
        #expect(store.details["ABC-123"] == details)
    }

    @Test func aFailedDetailsReadKeepsTheMessageAndLogsIt() async {
        await enableTracker()
        spy.detailsResult = .failure(TrackerError.command("Issue does not exist"))

        await store.loadDetails("ABC-123")

        #expect(store.detailErrors["ABC-123"] == "Issue does not exist")
        #expect(store.details["ABC-123"] == nil)
        #expect(harness.lastActivity?.title == "Cannot read ABC-123")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aProjectChangeDropsTheDetails() async {
        await enableTracker()
        spy.detailsResult = .success(details)
        await store.loadDetails("ABC-123")
        store.toggleDetails("ABC-123")

        harness.events.post(.projectChanged)

        #expect(store.details.isEmpty)
        #expect(store.expandedKey == nil)
    }

    // MARK: Assign and comment

    @Test func assignToMeUsesTheLoginOfTheToolAndReadsAgain() async throws {
        await enableTracker()
        await store.refresh()
        store.scope = .project
        try await waitUntil { spy.calls.count == 4 }

        #expect(store.canAssignToMe)
        store.assignToMe("ABC-123")

        try await waitUntil { store.busyKeys.isEmpty && spy.calls.contains(.assign(key: "ABC-123", user: "alex@example.com")) && spy.calls.count == 7 }
        #expect(harness.lastActivity?.title == "Assigned ABC-123 to you")
        #expect(harness.lastActivity?.detail == "jira issue assign ABC-123 alex@example.com")
    }

    @Test func assignToMeIsOffForMineAndWithoutALogin() async {
        await enableTracker()
        await store.refresh()

        #expect(store.canAssignToMe == false)

        spy.toolStateResult = .notLoggedIn
        await store.refresh()
        store.assignToMe("ABC-123")

        #expect(store.user == nil)
        #expect(spy.calls.contains(.assign(key: "ABC-123", user: "alex@example.com")) == false)
    }

    @Test func aFailedAssignIsLogged() async throws {
        await enableTracker()
        await store.refresh()
        spy.assignError = TrackerError.command("User not found")

        store.assignToMe("ABC-123")

        try await waitUntil { harness.lastActivity?.title == "Could not assign ABC-123" }
        #expect(store.busyKeys.isEmpty)
    }

    @Test func aCommentIsSentTrimmedAndTheDetailsAreReadAgain() async {
        await enableTracker()
        spy.detailsResult = .success(details)

        let sent = await store.comment("ABC-123", text: "  Fixed on main.\n")

        #expect(sent)
        #expect(spy.calls == [.comment(key: "ABC-123", text: "Fixed on main."), .details(key: "ABC-123")])
        #expect(store.busyKeys.isEmpty)
        #expect(harness.lastActivity?.title == "Commented on ABC-123")
    }

    @Test func anEmptyOrFailedCommentReportsFalse() async {
        await enableTracker()

        #expect(await store.comment("ABC-123", text: " \n ") == false)
        #expect(spy.calls.isEmpty)

        spy.commentError = TrackerError.command("Error: 403")
        #expect(await store.comment("ABC-123", text: "Hello") == false)
        #expect(harness.lastActivity?.title == "Could not comment on ABC-123")
        #expect(harness.lastActivity?.outcome == .failure)
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
