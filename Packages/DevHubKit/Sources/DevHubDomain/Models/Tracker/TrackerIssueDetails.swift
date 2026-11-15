import Foundation

package struct TrackerIssueDetails: Identifiable, Hashable, Sendable {
    package let key: String
    package var description: String
    package var reporter: String?
    package var createdAt: Date?
    package var labels: [String]
    package var components: [String]
    package var parent: TrackerIssueLink?
    package var subtasks: [TrackerIssueLink]
    package var comments: [TrackerComment]

    package var id: String {
        key
    }

    package init(
        key: String,
        description: String,
        reporter: String?,
        createdAt: Date?,
        labels: [String],
        components: [String],
        parent: TrackerIssueLink?,
        subtasks: [TrackerIssueLink],
        comments: [TrackerComment]
    ) {
        self.key = key
        self.description = description
        self.reporter = reporter
        self.createdAt = createdAt
        self.labels = labels
        self.components = components
        self.parent = parent
        self.subtasks = subtasks
        self.comments = comments
    }
}
