import Foundation
import DevHubDomain
import DevHubUI

struct TicketDetailsModel: Equatable {
    var description: String?
    var facts: [String]
    var dueTag: TagModel?
    var labels: [String]
    var components: [String]
    var fixVersions: [String]
    var parent: TicketLinkModel?
    var subtasks: [TicketLinkModel]
    var links: [TicketLinkModel]
    var attachmentsText: String?
    var timeText: String?
    var watchersText: String?
    var isWatching: Bool
    var comments: [TicketCommentModel]
    var recentCount: Int
    var earlierCommentsTitle: String?

    var recentComments: [TicketCommentModel] {
        Array(comments.suffix(recentCount))
    }

    var hasFacts: Bool {
        facts.isEmpty == false || dueTag != nil || labels.isEmpty == false || components.isEmpty == false || fixVersions.isEmpty == false
    }

    static let preview = TicketDetailsMapper.model(
        for: TrackerIssueDetails(
            key: "ABC-123",
            description: "Steps:\n1. Open the login screen without a network connection.\n2. Tap Log In.\n\nThe button stays disabled until the app restarts.",
            reporter: "Sam",
            createdAt: Date(timeIntervalSinceNow: -6 * 86_400),
            labels: ["ios", "login"],
            components: ["Auth"],
            parent: TrackerIssueLink(key: "ABC-100", summary: "Login flow rework", status: "In Progress", statusCategory: .inProgress),
            subtasks: [TrackerIssueLink(key: "ABC-131", summary: "Add a unit test for the retry", status: "To Do", statusCategory: .toDo)],
            comments: [TrackerComment(id: "1", author: "Sam", body: "Happens on iOS 18 too.", createdAt: Date(timeIntervalSinceNow: -2 * 86_400))],
            fixVersions: ["2.4.0"],
            dueDate: Date(timeIntervalSinceNow: 3 * 86_400),
            links: [TrackerIssueRelation(relation: "blocks", issue: TrackerIssueLink(key: "ABC-140", summary: "Release 2.4.0 checklist", status: "To Do", statusCategory: .toDo))],
            attachments: ["login-screen.png"],
            originalEstimateSeconds: 14_400,
            timeSpentSeconds: 5_400,
            remainingEstimateSeconds: 9_000,
            watchers: 3,
            isWatching: false
        ),
        ticketURL: URL(string: "https://jira.example.com/browse/ABC-123"),
        now: .now
    )
}
