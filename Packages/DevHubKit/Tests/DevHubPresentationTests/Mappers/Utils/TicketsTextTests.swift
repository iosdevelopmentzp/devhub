import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct TicketsTextTests {
    @Test func everyScopeAndOrderHasATitle() {
        #expect(IssueScope.allCases.map(TicketsText.title(for:)) == ["Mine", "Sprint", "Reported", "Watching", "Project"])
        #expect(IssueOrder.allCases.map(TicketsText.title(for:)) == ["Last updated", "Newest", "Priority"])
        #expect(TicketGrouping.allCases.map(\.title) == ["Status", "Type", "Assignee", "Priority"])
    }

    @Test func emptyTextsFollowTheScopeAndTheDoneChoice() {
        #expect(TicketsText.emptyTitle(includesDone: false) == "No open tickets")
        #expect(TicketsText.emptyTitle(includesDone: true) == "No tickets")
        #expect(TicketsText.emptyDescription(for: .sprint).contains("sprint"))
        #expect(Set(IssueScope.allCases.map(TicketsText.emptyDescription(for:))).count == IssueScope.allCases.count)
        #expect(TicketsText.doneToggleTitle == "Done in the last 14 days")
    }

    @Test func theTypesTitleCountsTheHiddenTypes() {
        #expect(TicketsText.typesTitle(hidden: 0) == "Types")
        #expect(TicketsText.typesTitle(hidden: 2) == "Types (2 hidden)")
    }
}
