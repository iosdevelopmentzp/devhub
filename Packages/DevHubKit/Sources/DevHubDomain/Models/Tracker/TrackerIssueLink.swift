import Foundation

package struct TrackerIssueLink: Identifiable, Hashable, Codable, Sendable {
    package let key: String
    package var summary: String
    package var status: String
    package var statusCategory: IssueStatusCategory

    package var id: String {
        key
    }

    package init(key: String, summary: String, status: String, statusCategory: IssueStatusCategory) {
        self.key = key
        self.summary = summary
        self.status = status
        self.statusCategory = statusCategory
    }
}
