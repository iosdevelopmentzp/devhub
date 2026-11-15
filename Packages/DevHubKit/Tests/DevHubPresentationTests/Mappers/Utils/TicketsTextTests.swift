import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketsTextTests {
    @Test func everyScopeAndOrderHasATitle() {
        #expect(IssueScope.allCases.map(TicketsText.title(for:)) == ["Mine", "Starred", "Recent", "Sprint", "Reported", "Watching", "Project"])
        #expect(IssueOrder.allCases.map(TicketsText.title(for:)) == ["Last updated", "Newest", "Priority"])
        #expect(TicketGrouping.allCases.map(\.title) == ["Status", "Type", "Assignee", "Priority"])
    }

    @Test func emptyTextsFollowTheScopeAndTheDoneChoice() {
        #expect(TicketsText.emptyTitle(for: .mine, includesDone: false) == "No open tickets")
        #expect(TicketsText.emptyTitle(for: .mine, includesDone: true) == "No tickets")
        #expect(TicketsText.emptyTitle(for: .starred, includesDone: true) == "No starred tickets")
        #expect(TicketsText.emptyDescription(for: .sprint).contains("sprint"))
        #expect(TicketsText.emptyDescription(for: .starred).contains("Star"))
        #expect(Set(IssueScope.allCases.map(TicketsText.emptyDescription(for:))).count == IssueScope.allCases.count)
        #expect(TicketsText.doneToggleTitle == "Done in the last 14 days")
        #expect(TicketsText.loadMoreTitle == "Show up to 100 tickets")
    }

    @Test func theTypesTitleCountsTheHiddenTypes() {
        #expect(TicketsText.typesTitle(hidden: 0) == "Types")
        #expect(TicketsText.typesTitle(hidden: 2) == "Types (2 hidden)")
    }

    @Test func theReadTextNeedsADate() {
        #expect(TicketsText.readText(nil) == nil)
        #expect(TicketsText.readText(Date(timeIntervalSinceNow: -60))?.hasPrefix("read ") == true)
    }

    @Test func starTextsFollowTheStar() {
        #expect(TicketsText.starTitle(isStarred: false) == "Star")
        #expect(TicketsText.starTitle(isStarred: true) == "Unstar")
        #expect(TicketsText.starHint(isStarred: true) == "Remove the star")
        #expect(TicketsText.staleNotice("Error: 401") == "Cannot read tickets: Error: 401. The list below is the last one that was read.")
    }
}
