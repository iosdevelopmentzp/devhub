import Testing
@testable import DevHubDomain

@Suite struct TrackerQueryPolicyTests {
    @Test func mineAsksForTheOpenTicketsOfTheUser() {
        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: false, settings: .standard, starred: []) == "assignee = currentUser() AND statusCategory != Done")
    }

    @Test func projectAsksForEveryOpenTicket() {
        #expect(TrackerQueryPolicy.jql(for: .project, includesDone: false, settings: .standard, starred: []) == "statusCategory != Done")
    }

    @Test func eachScopeHasItsClause() {
        #expect(TrackerQueryPolicy.jql(for: .sprint, includesDone: false, settings: .standard, starred: []) == "sprint in openSprints() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.jql(for: .reported, includesDone: false, settings: .standard, starred: []) == "reporter = currentUser() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.jql(for: .watching, includesDone: false, settings: .standard, starred: []) == "watcher = currentUser() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.jql(for: .recent, includesDone: false, settings: .standard, starred: []) == "issuekey in issueHistory() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.scopeClause(.project) == nil)
        #expect(TrackerQueryPolicy.scopeClause(.starred) == nil)
    }

    @Test func recentDoneTicketsAreAddedOnRequest() {
        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: true, settings: .standard, starred: []) == "assignee = currentUser() AND (statusCategory != Done OR updated >= -14d)")
    }

    @Test func aFilterIsAddedInParentheses() {
        var settings = TrackerSettings.standard
        settings.filter = "type != Epic OR labels = ios"

        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: false, settings: settings, starred: []) == "assignee = currentUser() AND statusCategory != Done AND (type != Epic OR labels = ios)")
    }

    @Test func starredAsksForTheStarredKeysWithNoOtherClause() {
        var settings = TrackerSettings.standard
        settings.filter = "type != Epic"

        #expect(TrackerQueryPolicy.jql(for: .starred, includesDone: false, settings: settings, starred: ["ABC-123", "ABC-7"]) == "issuekey in (ABC-123, ABC-7)")
    }

    @Test func starredWithNoKeyHasNoQuery() {
        #expect(TrackerQueryPolicy.jql(for: .starred, includesDone: true, settings: .standard, starred: []) == nil)
        #expect(TrackerQueryPolicy.jql(for: .starred, includesDone: true, settings: .standard, starred: ["ABC-1) OR project = X"]) == nil)
    }

    @Test func aTextThatIsNotAKeyNeverEntersTheQuery() {
        #expect(TrackerQueryPolicy.starredClause(["ABC-1", "bad key", "ABC-2) OR 1=1", "A1_B-22"]) == "issuekey in (ABC-1, A1_B-22)")
    }

    @Test func aKeyIsLettersADashAndDigits() {
        #expect(TrackerQueryPolicy.isIssueKey("ABC-123"))
        #expect(TrackerQueryPolicy.isIssueKey("ABC-") == false)
        #expect(TrackerQueryPolicy.isIssueKey("-12") == false)
        #expect(TrackerQueryPolicy.isIssueKey("ABC-12 ") == false)
        #expect(TrackerQueryPolicy.isIssueKey("1BC-12") == false)
    }
}
