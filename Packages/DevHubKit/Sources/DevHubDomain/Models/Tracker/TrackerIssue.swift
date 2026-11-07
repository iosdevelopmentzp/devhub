import Foundation

package struct TrackerIssue: Identifiable, Hashable, Sendable {
    package let key: String
    package var summary: String
    package var status: String
    package var statusCategory: IssueStatusCategory
    package var type: String
    package var priority: String?
    package var assignee: String?
    package var url: URL?
    package var updatedAt: Date?

    package var id: String {
        key
    }

    package init(
        key: String,
        summary: String,
        status: String,
        statusCategory: IssueStatusCategory,
        type: String,
        priority: String?,
        assignee: String?,
        url: URL?,
        updatedAt: Date?
    ) {
        self.key = key
        self.summary = summary
        self.status = status
        self.statusCategory = statusCategory
        self.type = type
        self.priority = priority
        self.assignee = assignee
        self.url = url
        self.updatedAt = updatedAt
    }
}
