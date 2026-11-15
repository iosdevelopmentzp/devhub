import Foundation

package struct TrackerIssueRelation: Identifiable, Hashable, Codable, Sendable {
    package var relation: String
    package var issue: TrackerIssueLink

    package var id: String {
        "\(relation):\(issue.key)"
    }

    package init(relation: String, issue: TrackerIssueLink) {
        self.relation = relation
        self.issue = issue
    }
}
