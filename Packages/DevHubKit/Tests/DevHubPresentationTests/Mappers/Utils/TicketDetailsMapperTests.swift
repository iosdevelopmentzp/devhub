import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketDetailsMapperTests {
    @Test func theModelCarriesTheDescriptionFactsLinksAndComments() {
        let model = TicketDetailsMapper.model(for: details(comments: 2))

        #expect(model.description == "The button stays disabled.")
        #expect(model.facts.first == "Reported by Sam")
        #expect(model.facts.count == 2)
        #expect(model.labels == ["ios"])
        #expect(model.components == ["Auth"])
        #expect(model.parent == TicketLinkModel(id: "ABC-100", key: "ABC-100", summary: "Login flow rework", statusTag: TagModel("In Progress", tint: .blue, hint: "Status in the tracker")))
        #expect(model.subtasks.map(\.key) == ["ABC-131"])
        #expect(model.subtasks.first?.statusTag.tint == .secondary)
        #expect(model.comments.map(\.id) == ["0", "1"])
        #expect(model.comments.first?.author == "Sam")
        #expect(model.comments.first?.dateText?.isEmpty == false)
        #expect(model.earlierCommentsText == nil)
    }

    @Test func onlyTheLastCommentsShowAndTheRestPointsToTheBrowser() {
        let model = TicketDetailsMapper.model(for: details(comments: 8))

        #expect(model.comments.map(\.id) == ["3", "4", "5", "6", "7"])
        #expect(model.earlierCommentsText == "3 earlier comments in the browser")
    }

    @Test func emptyValuesHaveFallbacks() {
        var empty = details(comments: 0)
        empty.description = "  \n"
        empty.reporter = nil
        empty.createdAt = nil
        empty.parent = nil
        empty.comments = [TrackerComment(id: "9", author: "", body: "Hi", createdAt: nil)]

        let model = TicketDetailsMapper.model(for: empty)

        #expect(model.description == nil)
        #expect(model.facts.isEmpty)
        #expect(model.parent == nil)
        #expect(model.comments.first?.author == "Someone")
        #expect(model.comments.first?.dateText == nil)
        #expect(TicketDetailsMapper.link(for: TrackerIssueLink(key: "ABC-1", summary: "", status: "", statusCategory: .unknown)).statusTag.text == "Unknown")
    }

    private func details(comments: Int) -> TrackerIssueDetails {
        TrackerIssueDetails(
            key: "ABC-123",
            description: "The button stays disabled.",
            reporter: "Sam",
            createdAt: Date(timeIntervalSinceNow: -86_400),
            labels: ["ios"],
            components: ["Auth"],
            parent: TrackerIssueLink(key: "ABC-100", summary: "Login flow rework", status: "In Progress", statusCategory: .inProgress),
            subtasks: [TrackerIssueLink(key: "ABC-131", summary: "Add a test", status: "To Do", statusCategory: .toDo)],
            comments: (0..<comments).map { TrackerComment(id: "\($0)", author: "Sam", body: "Comment \($0)", createdAt: Date(timeIntervalSinceNow: -3_600)) }
        )
    }
}
