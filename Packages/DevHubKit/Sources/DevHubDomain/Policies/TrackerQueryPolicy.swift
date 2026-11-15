import Foundation

package enum TrackerQueryPolicy {
    package static let pageSize = 50
    package static let maxPageSize = 100
    package static let recentDoneDays = 14

    package static func jql(for scope: IssueScope, includesDone: Bool, settings: TrackerSettings, starred: [String]) -> String? {
        guard scope != .starred else { return starredClause(starred) }
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
        case .recent: "issuekey in issueHistory()"
        case .sprint: "sprint in openSprints()"
        case .reported: "reporter = currentUser()"
        case .watching: "watcher = currentUser()"
        case .starred, .project: nil
        }
    }

    package static func starredClause(_ keys: [String]) -> String? {
        let valid = keys.filter(isIssueKey)
        guard valid.isEmpty == false else { return nil }
        return "issuekey in (\(valid.joined(separator: ", ")))"
    }

    package static func isIssueKey(_ key: String) -> Bool {
        key.wholeMatch(of: /[A-Za-z][A-Za-z0-9_]*-[0-9]+/) != nil
    }
}
