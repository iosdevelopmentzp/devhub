import Foundation
import DevHubDomain
import DevHubUI

struct TicketRowModel: Identifiable, Equatable {
    let id: String
    var key: String
    var summary: String
    var typeIcon: String
    var typeTint: Tint
    var typeHint: String
    var statusTag: TagModel
    var priorityTag: TagModel?
    var dueTag: TagModel?
    var labelTags: [TagModel]
    var assignee: String?
    var updatedText: String?
    var url: URL?
    var branchName: String
    var startTitle: String
    var canStart: Bool
    var moveTargets: [String]
    var isBusy: Bool
    var isExpanded: Bool
    var isStarred: Bool
    var starTitle: String
    var starHint: String
    var canAssignToMe: Bool
    var canUnassign: Bool
    var canWatch: Bool
    var keyAndSummary: String

    static let preview = TicketRowMapper.model(
        for: TrackerIssue(
            key: "ABC-123",
            summary: "Login button stays disabled after a failed request",
            status: "To Do",
            statusCategory: .toDo,
            type: "Bug",
            priority: "High",
            assignee: "Alex",
            url: URL(string: "https://jira.example.com/browse/ABC-123"),
            updatedAt: Date(timeIntervalSinceNow: -3_600),
            labels: ["ios", "login", "auth"],
            dueDate: Date(timeIntervalSinceNow: 3 * 86_400)
        ),
        settings: .standard,
        isBusy: false,
        isExpanded: false,
        isStarred: true,
        canAssignToMe: true,
        canWatch: true,
        now: .now
    )
}
