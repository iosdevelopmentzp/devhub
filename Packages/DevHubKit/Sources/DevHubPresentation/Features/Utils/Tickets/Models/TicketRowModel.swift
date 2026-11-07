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
    var assignee: String?
    var updatedText: String?
    var url: URL?
    var branchName: String
    var startTitle: String
    var canStart: Bool
    var moveTargets: [String]
    var isBusy: Bool

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
            updatedAt: Date(timeIntervalSinceNow: -3_600)
        ),
        settings: .standard,
        isBusy: false
    )
}
