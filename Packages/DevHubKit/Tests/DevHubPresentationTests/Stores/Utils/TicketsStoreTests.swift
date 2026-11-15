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

    private let story = TrackerIssue(key: "ABC-124", summary: "Welcome screen", status: "To Do", statusCategory: .toDo, type: "Story", priority: nil, assignee: nil, url: nil, updatedAt: nil)

    private let mineQuery = SpyIssueTrackerRepository.Call.issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", order: .updated, limit: 50)

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
        #expect(store.readAt != nil)
        #expect(spy.calls == [.toolState, mineQuery])
    }

    @Test func aSecondRefreshSkipsTheToolCheck() async {
        await enableTracker()

        await store.refresh()
        await store.refresh()

        #expect(spy.calls == [.toolState, mineQuery, mineQuery])
    }

    @Test func reloadAlwaysChecksTheTool() async {
        await enableTracker()

        await store.refresh()
        await store.reload()

        #expect(spy.calls == [.toolState, mineQuery, .toolState, mineQuery])
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
        #expect(spy.calls == [.toolState, mineQuery])
    }

    @Test func aFailedReadAfterASkippedCheckChecksTheToolAgain() async {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()
        spy.issuesResult = .failure(TrackerError.command("Error: 401"))
        spy.toolStateResult = .notLoggedIn

        await store.refresh()

        #expect(spy.calls == [.toolState, mineQuery, mineQuery, .toolState])
        #expect(store.toolState == .notLoggedIn)
        #expect(store.issues.isEmpty)
        #expect(store.error == "Error: 401")
    }

    @Test func aFailedReadKeepsTheLastList() async {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()
        spy.issuesResult = .failure(TrackerError.command("Error: 502"))

        await store.refresh()

        #expect(store.issues == [issue])
        #expect(store.error == "Error: 502")
        #expect(store.readAt != nil)
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
        #expect(store.readAt == nil)
    }

    // MARK: Cache

    @Test func theLastListIsSavedAndShownAtTheNextStart() async {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()

        #expect(harness.store.data(forKey: "utils.tickets.cache.lists.ABC") != nil)

        let next = StoreHarness(store: harness.store)
        await enableTracker(next)

        #expect(next.tickets.issues == [issue])
        #expect(next.tickets.readAt != nil)
        #expect(next.spies.tracker.calls.isEmpty)
    }

    @Test func aScopeChangeShowsItsLastListAtOnce() async throws {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()
        spy.issuesResult = .success([story])
        store.scope = .project
        try await waitUntil { store.issues == [story] }

        store.scope = .mine

        #expect(store.issues == [issue])
        try await waitUntil { store.issues == [story] }
    }

    @Test func theReadyToolIsSavedAndTheNextStartSkipsTheCheck() async {
        await enableTracker()
        await store.refresh()

        #expect(harness.store.stringMap(forKey: "utils.tickets.tool") == ["version": "1.7.0", "user": "alex@example.com"])

        let next = StoreHarness(store: harness.store)
        await enableTracker(next)
        await next.tickets.refresh()

        #expect(next.tickets.toolState == .ready(version: "1.7.0", user: "alex@example.com"))
        #expect(next.spies.tracker.calls == [mineQuery])
    }

    @Test func aToolThatIsNotReadyForgetsTheSavedState() async {
        await enableTracker()
        await store.refresh()
        spy.toolStateResult = .missing

        await store.reload()

        #expect(harness.store.stringMap(forKey: "utils.tickets.tool") == nil)
    }

    @Test func detailsAreSavedAndShownAtTheNextStart() async {
        await enableTracker()
        spy.detailsResult = .success(details)
        await store.loadDetails("ABC-123")

        let next = StoreHarness(store: harness.store)
        await enableTracker(next)

        #expect(next.tickets.details["ABC-123"] == details)
    }

    // MARK: Stars

    @Test func aStarIsSavedAndPinsTheTicketWithoutARead() async {
        await enableTracker()

        store.toggleStar("ABC-123")

        #expect(store.starred == ["ABC-123"])
        #expect(store.isStarred("ABC-123"))
        #expect(store.pinnedKeys == ["ABC-123"])
        #expect(harness.store.strings(forKey: "utils.tickets.starred.ABC") == ["ABC-123"])
        #expect(spy.calls.isEmpty)

        store.toggleStar("ABC-123")

        #expect(store.starred.isEmpty)
        #expect(harness.store.strings(forKey: "utils.tickets.starred.ABC") == [])
    }

    @Test func theStarredScopeAsksForTheStarredKeysAndPinsNothing() async throws {
        await enableTracker()
        store.toggleStar("ABC-123")

        store.scope = .starred

        #expect(store.pinnedKeys.isEmpty)
        try await waitUntil { spy.calls.contains(.issues(jql: "issuekey in (ABC-123)", project: "ABC", order: .updated, limit: 50)) }
    }

    @Test func theStarredScopeWithoutAStarReadsNoList() async {
        await enableTracker()
        store.scope = .starred

        await store.refresh()

        #expect(store.issues.isEmpty)
        #expect(spy.calls.allSatisfy { $0 == .toolState })
    }

    @Test func removingAStarInTheStarredScopeDropsTheTicketAtOnce() async throws {
        await enableTracker()
        store.toggleStar("ABC-123")
        store.toggleStar("ABC-124")
        store.scope = .starred
        spy.issuesResult = .success([issue, story])
        try await waitUntil { store.issues.count == 2 }
        spy.issuesResult = .success([story])

        store.toggleStar("ABC-123")

        #expect(store.issues == [story])
        try await waitUntil { spy.calls.contains(.issues(jql: "issuekey in (ABC-124)", project: "ABC", order: .updated, limit: 50)) }
    }

    // MARK: Load more

    @Test func loadMoreReadsUpToAHundredAndAScopeChangeResetsTheLimit() async throws {
        await enableTracker()
        spy.issuesResult = .success((1...50).map { TrackerIssue(key: "ABC-\($0)", summary: "", status: "", statusCategory: .toDo, type: "", priority: nil, assignee: nil, url: nil, updatedAt: nil) })
        await store.refresh()

        #expect(store.canLoadMore)
        store.loadMore()

        #expect(store.limit == 100)
        try await waitUntil { spy.calls.contains(.issues(jql: "assignee = currentUser() AND statusCategory != Done", project: "ABC", order: .updated, limit: 100)) }
        #expect(store.canLoadMore == false)

        store.scope = .project

        #expect(store.limit == 50)
    }

    // MARK: Move

    @Test func aMoveTransitionsLogsAndReadsAgain() async throws {
        await enableTracker()
        spy.issuesResult = .success([issue])
        await store.refresh()

        store.move("ABC-123", to: "In Review")

        #expect(store.busyKeys == ["ABC-123"])
        try await waitUntil { store.busyKeys.isEmpty && spy.calls.count == 4 }
        #expect(spy.calls.suffix(2) == [.transition(key: "ABC-123", status: "In Review"), mineQuery])
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
        #expect(spy.calls.contains(mineQuery) == false)
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
        #expect(harness.store.data(forKey: "utils.tickets.cache.details.ABC") != nil)

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

    // MARK: Assign, watch and comment

    @Test func assignToMeUsesTheLoginOfTheToolAndReadsAgain() async throws {
        await enableTracker()
        await store.refresh()
        store.scope = .project
        try await waitUntil { spy.calls.count == 3 }

        #expect(store.canAssignToMe)
        store.assignToMe("ABC-123")

        try await waitUntil { store.busyKeys.isEmpty && spy.calls.count == 5 }
        #expect(spy.calls.suffix(2) == [.assign(key: "ABC-123", user: "alex@example.com"), .issues(jql: "statusCategory != Done", project: "ABC", order: .updated, limit: 50)])
        #expect(harness.lastActivity?.title == "Assigned ABC-123 to you")
        #expect(harness.lastActivity?.detail == "jira issue assign ABC-123 alex@example.com")
    }

    @Test func assignToMeIsOffForMineAndWithoutALogin() async {
        await enableTracker()
        await store.refresh()

        #expect(store.canAssignToMe == false)
        #expect(store.canWatch)

        spy.toolStateResult = .notLoggedIn
        await store.reload()
        store.assignToMe("ABC-123")
        store.watch("ABC-123")

        #expect(store.user == nil)
        #expect(store.canWatch == false)
        #expect(spy.calls.contains(.assign(key: "ABC-123", user: "alex@example.com")) == false)
        #expect(spy.calls.contains(.watch(key: "ABC-123", user: "alex@example.com")) == false)
    }

    @Test func aFailedAssignIsLogged() async throws {
        await enableTracker()
        await store.refresh()
        spy.assignError = TrackerError.command("User not found")

        store.assignToMe("ABC-123")

        try await waitUntil { harness.lastActivity?.title == "Could not assign ABC-123" }
        #expect(store.busyKeys.isEmpty)
    }

    @Test func unassignRemovesTheAssigneeAndReadsAgain() async throws {
        await enableTracker()
        await store.refresh()

        store.unassign("ABC-123")

        try await waitUntil { store.busyKeys.isEmpty && spy.calls.count == 4 }
        #expect(spy.calls.suffix(2) == [.unassign(key: "ABC-123"), mineQuery])
        #expect(harness.lastActivity?.title == "Removed the assignee of ABC-123")
        #expect(harness.lastActivity?.detail == "jira issue assign ABC-123 x")
    }

    @Test func watchAddsTheUserThenReadsTheDetailsAndTheList() async throws {
        await enableTracker()
        spy.detailsResult = .success(details)
        await store.refresh()

        store.watch("ABC-123")

        try await waitUntil { store.busyKeys.isEmpty && spy.calls.count == 5 }
        #expect(spy.calls.suffix(3) == [.watch(key: "ABC-123", user: "alex@example.com"), .details(key: "ABC-123"), mineQuery])
        #expect(harness.lastActivity?.title == "Watching ABC-123")
        #expect(harness.lastActivity?.detail == "jira issue watch ABC-123 alex@example.com")
    }

    @Test func aFailedWatchIsLogged() async throws {
        await enableTracker()
        await store.refresh()
        spy.watchError = TrackerError.command("Error: 403")

        store.watch("ABC-123")

        try await waitUntil { harness.lastActivity?.title == "Could not watch ABC-123" }
        #expect(harness.lastActivity?.outcome == .failure)
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
        await enableTracker(harness)
    }

    private func enableTracker(_ harness: StoreHarness) async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(tracker: TrackerConfig(kind: .jira, project: "ABC")), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
    }
}
