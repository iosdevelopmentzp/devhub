import Foundation

package enum TrackerQueryPolicy {
    package static let pageSize = 50
    package static let recentDoneDays = 14

    package static func jql(for scope: IssueScope, includesDone: Bool, settings: TrackerSettings) -> String {
        var clauses: [String] = []
        if let clause = scopeClause(scope) {
            clauses.append(clause)
        }
        clauses.append(includesDone ? "(statusCategory != Done OR updated >= -\(recentDoneDays)d)" : "statusCategory != Done")
        if let filter = settings.filter {
            clauses.append("(\(filter))")
        }
        return clauses.joined(separator: " AND ")
    }

    package static func scopeClause(_ scope: IssueScope) -> String? {
        switch scope {
        case .mine: "assignee = currentUser()"
        case .sprint: "sprint in openSprints()"
        case .reported: "reporter = currentUser()"
        case .watching: "watcher = currentUser()"
        case .project: nil
        }
    }
}
