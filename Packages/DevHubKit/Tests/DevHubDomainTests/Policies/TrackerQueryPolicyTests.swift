import Testing
@testable import DevHubDomain

@Suite struct TrackerQueryPolicyTests {
    @Test func mineAsksForTheOpenTicketsOfTheUser() {
        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: false, settings: .standard) == "assignee = currentUser() AND statusCategory != Done")
    }

    @Test func projectAsksForEveryOpenTicket() {
        #expect(TrackerQueryPolicy.jql(for: .project, includesDone: false, settings: .standard) == "statusCategory != Done")
    }

    @Test func eachScopeHasItsClause() {
        #expect(TrackerQueryPolicy.jql(for: .sprint, includesDone: false, settings: .standard) == "sprint in openSprints() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.jql(for: .reported, includesDone: false, settings: .standard) == "reporter = currentUser() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.jql(for: .watching, includesDone: false, settings: .standard) == "watcher = currentUser() AND statusCategory != Done")
        #expect(TrackerQueryPolicy.scopeClause(.project) == nil)
    }

    @Test func recentDoneTicketsAreAddedOnRequest() {
        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: true, settings: .standard) == "assignee = currentUser() AND (statusCategory != Done OR updated >= -14d)")
    }

    @Test func aFilterIsAddedInParentheses() {
        var settings = TrackerSettings.standard
        settings.filter = "type != Epic OR labels = ios"

        #expect(TrackerQueryPolicy.jql(for: .mine, includesDone: false, settings: settings) == "assignee = currentUser() AND statusCategory != Done AND (type != Epic OR labels = ios)")
    }
}
