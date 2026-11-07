import Testing
@testable import DevHubDomain

@Suite struct TrackerQueryPolicyTests {
    @Test func mineAsksForTheOpenTicketsOfTheUser() {
        #expect(TrackerQueryPolicy.jql(for: .mine, settings: .standard) == "assignee = currentUser() AND statusCategory != Done")
    }

    @Test func projectAsksForEveryOpenTicket() {
        #expect(TrackerQueryPolicy.jql(for: .project, settings: .standard) == "statusCategory != Done")
    }

    @Test func aFilterIsAddedInParentheses() {
        var settings = TrackerSettings.standard
        settings.filter = "type != Epic OR labels = ios"

        #expect(TrackerQueryPolicy.jql(for: .mine, settings: settings) == "assignee = currentUser() AND statusCategory != Done AND (type != Epic OR labels = ios)")
    }
}
