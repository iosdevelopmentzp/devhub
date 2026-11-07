import Foundation

package enum TrackerQueryPolicy {
    package static let pageSize = 50

    package static func jql(for scope: IssueScope, settings: TrackerSettings) -> String {
        var clauses: [String] = []
        if scope == .mine {
            clauses.append("assignee = currentUser()")
        }
        clauses.append("statusCategory != Done")
        if let filter = settings.filter {
            clauses.append("(\(filter))")
        }
        return clauses.joined(separator: " AND ")
    }
}
