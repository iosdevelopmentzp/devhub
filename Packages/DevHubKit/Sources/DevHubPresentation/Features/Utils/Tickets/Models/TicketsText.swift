import Foundation
import DevHubDomain

enum TicketsText {
    static let scopeHint = "Mine: assigned to you. Sprint: the open sprints of the project. Reported: created by you. Watching: tickets you watch. Project: every ticket of the project."
    static let viewHint = "Group, sort and filter the tickets: by status, type, assignee or priority; done tickets of the last \(TrackerQueryPolicy.recentDoneDays) days; ticket types."

    static func title(for scope: IssueScope) -> String {
        switch scope {
        case .mine: "Mine"
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

    static let doneToggleTitle = "Done in the last \(TrackerQueryPolicy.recentDoneDays) days"

    static func emptyTitle(includesDone: Bool) -> String {
        includesDone ? "No tickets" : "No open tickets"
    }

    static func emptyDescription(for scope: IssueScope) -> String {
        switch scope {
        case .mine: "Nothing open is assigned to you in this project."
        case .sprint: "The project has no open sprint, or the sprint has no open tickets."
        case .reported: "You did not create an open ticket in this project."
        case .watching: "You do not watch an open ticket in this project."
        case .project: "The project has no open tickets."
        }
    }

    static func typesTitle(hidden: Int) -> String {
        hidden == 0 ? "Types" : "Types (\(hidden) hidden)"
    }
}
