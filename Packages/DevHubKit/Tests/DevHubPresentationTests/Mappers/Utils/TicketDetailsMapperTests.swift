import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct TicketDetailsMapperTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let ticketURL = URL(string: "https://jira.example.com/browse/ABC-123")

    @Test func theModelCarriesTheDescriptionFactsLinksAndComments() {
        let model = TicketDetailsMapper.model(for: details(comments: 2), ticketURL: ticketURL, now: now)

        #expect(model.description == "The button stays disabled.")
        #expect(model.facts.first == "Reported by Sam")
        #expect(model.facts.count == 2)
        #expect(model.labels == ["ios"])
        #expect(model.components == ["Auth"])
        #expect(model.fixVersions.isEmpty)
        #expect(model.parent == TicketLinkModel(id: "ABC-100", key: "ABC-100", summary: "Login flow rework", statusTag: TagModel("In Progress", tint: .blue, hint: "Status in the tracker"), relation: nil, url: URL(string: "https://jira.example.com/browse/ABC-100")))
        #expect(model.subtasks.map(\.key) == ["ABC-131"])
        #expect(model.subtasks.first?.statusTag.tint == .secondary)
        #expect(model.links.isEmpty)
        #expect(model.comments.map(\.id) == ["0", "1"])
        #expect(model.recentComments.map(\.id) == ["0", "1"])
        #expect(model.comments.first?.author == "Sam")
        #expect(model.comments.first?.dateText?.isEmpty == false)
        #expect(model.earlierCommentsTitle == nil)
        #expect(model.dueTag == nil)
        #expect(model.timeText == nil)
        #expect(model.watchersText == nil)
        #expect(model.attachmentsText == nil)
        #expect(model.isWatching == false)
        #expect(model.hasFacts)
    }

    @Test func everyCommentIsKeptAndTheLastFiveAreRecent() {
        let model = TicketDetailsMapper.model(for: details(comments: 8), ticketURL: nil, now: now)

        #expect(model.comments.count == 8)
        #expect(model.recentComments.map(\.id) == ["3", "4", "5", "6", "7"])
        #expect(model.earlierCommentsTitle == "Show 3 earlier comments")
        #expect(TicketDetailsMapper.model(for: details(comments: 6), ticketURL: nil, now: now).earlierCommentsTitle == "Show 1 earlier comment")
    }

    @Test func theNewMembersBecomeTagsLinesAndLinks() {
        var full = details(comments: 0)
        full.fixVersions = ["2.4.0"]
        full.dueDate = now.addingTimeInterval(-86_400)
        full.resolution = "Fixed"
        full.links = [
            TrackerIssueRelation(relation: "blocks", issue: TrackerIssueLink(key: "ABC-140", summary: "Checklist", status: "To Do", statusCategory: .toDo)),
            TrackerIssueRelation(relation: "", issue: TrackerIssueLink(key: "ABC-99", summary: "Endpoint", status: "Done", statusCategory: .done)),
        ]
        full.attachments = ["login-screen.png", "console.log"]
        full.originalEstimateSeconds = 14_400
        full.timeSpentSeconds = 5_400
        full.remainingEstimateSeconds = 9_000
        full.watchers = 3
        full.isWatching = true

        let model = TicketDetailsMapper.model(for: full, ticketURL: ticketURL, now: now)

        #expect(model.fixVersions == ["2.4.0"])
        #expect(model.facts.last == "Resolved: Fixed")
        #expect(model.dueTag?.tint == .secondary)
        #expect(model.links.map(\.id) == ["ABC-140", "ABC-99"])
        #expect(model.links[0].relation == "blocks")
        #expect(model.links[0].url == URL(string: "https://jira.example.com/browse/ABC-140"))
        #expect(model.links[1].relation == nil)
        #expect(model.attachmentsText == "2 files: login-screen.png, console.log")
        #expect(model.timeText == "Logged 1h 30m of 4h, 2h 30m left")
        #expect(model.watchersText == "3 watchers, you watch this ticket")
        #expect(model.isWatching)
    }

    @Test func anOpenTicketPastItsDueDateIsOverdue() {
        var open = details(comments: 0)
        open.dueDate = now.addingTimeInterval(-86_400)

        #expect(TicketDetailsMapper.model(for: open, ticketURL: nil, now: now).dueTag?.tint == .red)
    }

    @Test func timeAndWatcherTextsCoverEveryCombination() {
        #expect(TicketDetailsMapper.timeText(original: 14_400, spent: nil, remaining: nil) == "Estimate 4h")
        #expect(TicketDetailsMapper.timeText(original: nil, spent: 1_800, remaining: nil) == "Logged 30m")
        #expect(TicketDetailsMapper.timeText(original: nil, spent: nil, remaining: 600) == "10m left")
        #expect(TicketDetailsMapper.timeText(original: nil, spent: nil, remaining: nil) == nil)
        #expect(TicketDetailsMapper.watchersText(count: 1, isWatching: false) == "1 watcher")
        #expect(TicketDetailsMapper.watchersText(count: nil, isWatching: true) == nil)
        #expect(TicketDetailsMapper.attachmentsText([]) == nil)
        #expect(TicketDetailsMapper.attachmentsText(["a.png"]) == "1 file: a.png")
    }

    @Test func aLinkURLReplacesTheKeyInTheTicketURL() {
        #expect(TicketDetailsMapper.url(for: "ABC-9", from: ticketURL) == URL(string: "https://jira.example.com/browse/ABC-9"))
        #expect(TicketDetailsMapper.url(for: "ABC-9", from: nil) == nil)
        #expect(TicketDetailsMapper.url(for: "ABC-9", from: URL(string: "https://jira.example.com")) == nil)
    }

    @Test func emptyValuesHaveFallbacks() {
        var empty = details(comments: 0)
        empty.description = "  \n"
        empty.reporter = nil
        empty.createdAt = nil
        empty.parent = nil
        empty.comments = [TrackerComment(id: "9", author: "", body: "Hi", createdAt: nil)]

        let model = TicketDetailsMapper.model(for: empty, ticketURL: nil, now: now)

        #expect(model.description == nil)
        #expect(model.facts.isEmpty)
        #expect(model.parent == nil)
        #expect(model.comments.first?.author == "Someone")
        #expect(model.comments.first?.dateText == nil)
        #expect(model.subtasks.first?.url == nil)
        #expect(TicketDetailsMapper.link(for: TrackerIssueLink(key: "ABC-1", summary: "", status: "", statusCategory: .unknown), ticketURL: nil).statusTag.text == "Unknown")
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
