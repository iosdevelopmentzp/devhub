import Foundation
import DevHubDomain

struct TicketDetailsModel: Equatable {
    var description: String?
    var facts: [String]
    var labels: [String]
    var components: [String]
    var parent: TicketLinkModel?
    var subtasks: [TicketLinkModel]
    var comments: [TicketCommentModel]
    var earlierCommentsText: String?

    static let preview = TicketDetailsMapper.model(for: TrackerIssueDetails(
        key: "ABC-123",
        description: "Steps:\n1. Open the login screen without a network connection.\n2. Tap Log In.\n\nThe button stays disabled until the app restarts.",
        reporter: "Sam",
        createdAt: Date(timeIntervalSinceNow: -6 * 86_400),
        labels: ["ios", "login"],
        components: ["Auth"],
        parent: TrackerIssueLink(key: "ABC-100", summary: "Login flow rework", status: "In Progress", statusCategory: .inProgress),
        subtasks: [TrackerIssueLink(key: "ABC-131", summary: "Add a unit test for the retry", status: "To Do", statusCategory: .toDo)],
        comments: [TrackerComment(id: "1", author: "Sam", body: "Happens on iOS 18 too.", createdAt: Date(timeIntervalSinceNow: -2 * 86_400))]
    ))
}
