import Foundation
import DevHubDomain
import DevHubUI

enum TicketsText {
    static let scopeHint = "Mine: assigned to you. Starred: the tickets you starred. Recent: the tickets you opened last. Sprint: the open sprints of the project. Reported: created by you. Watching: tickets you watch. Project: every ticket of the project."
    static let viewHint = "Group, sort and filter the tickets: by status, type, assignee or priority; done tickets of the last \(TrackerQueryPolicy.recentDoneDays) days; ticket types."
    static let loadMoreTitle = "Show up to \(TrackerQueryPolicy.maxPageSize) tickets"
    static let loadMoreHint = "Reads the list again with a higher limit. jira issue list --paginate 0:\(TrackerQueryPolicy.maxPageSize)"
    static let starredSectionTitle = "Starred"
    static let doneToggleTitle = "Done in the last \(TrackerQueryPolicy.recentDoneDays) days"
    static let readFailureTitle = "Cannot read tickets"

    static func title(for scope: IssueScope) -> String {
        switch scope {
        case .mine: "Mine"
        case .starred: "Starred"
        case .recent: "Recent"
        case .sprint: "Sprint"
        case .reported: "Reported"
        case .watching: "Watching"
        case .project: "Project"
        }
    }

    static func title(for order: IssueOrder) -> String {
        switch order {
        case .updated: "Last updated"
        case .created: "Newest"
        case .priority: "Priority"
        }
    }

    static func emptyTitle(for scope: IssueScope, includesDone: Bool) -> String {
        guard scope != .starred else { return "No starred tickets" }
        return includesDone ? "No tickets" : "No open tickets"
    }

    static func emptyDescription(for scope: IssueScope) -> String {
        switch scope {
        case .mine: "Nothing open is assigned to you in this project."
        case .starred: "Star a ticket with the star in its row or in its menu. Starred tickets stay on top of every list."
        case .recent: "You did not open a ticket in Jira lately."
        case .sprint: "The project has no open sprint, or the sprint has no open tickets."
        case .reported: "You did not create an open ticket in this project."
        case .watching: "You do not watch an open ticket in this project."
        case .project: "The project has no open tickets."
        }
    }

    static func typesTitle(hidden: Int) -> String {
        hidden == 0 ? "Types" : "Types (\(hidden) hidden)"
    }

    static func readText(_ readAt: Date?) -> String? {
        readAt.map { "read \($0.relativeDescription)" }
    }

    static func staleNotice(_ error: String) -> String {
        "\(readFailureTitle): \(error). The list below is the last one that was read."
    }

    static func starHint(isStarred: Bool) -> String {
        isStarred ? "Remove the star" : "Star this ticket. It stays on top of the list and in the Starred scope."
    }

    static func starTitle(isStarred: Bool) -> String {
        isStarred ? "Unstar" : "Star"
    }
}
