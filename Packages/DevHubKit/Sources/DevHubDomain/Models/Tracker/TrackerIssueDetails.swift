import Foundation

package struct TrackerIssueDetails: Identifiable, Hashable, Codable, Sendable {
    package let key: String
    package var description: String
    package var reporter: String?
    package var createdAt: Date?
    package var labels: [String]
    package var components: [String]
    package var parent: TrackerIssueLink?
    package var subtasks: [TrackerIssueLink]
    package var comments: [TrackerComment]
    package var fixVersions: [String] = []
    package var dueDate: Date?
    package var resolution: String?
    package var links: [TrackerIssueRelation] = []
    package var attachments: [String] = []
    package var originalEstimateSeconds: Int?
    package var timeSpentSeconds: Int?
    package var remainingEstimateSeconds: Int?
    package var watchers: Int?
    package var isWatching: Bool?

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
        comments: [TrackerComment],
        fixVersions: [String] = [],
        dueDate: Date? = nil,
        resolution: String? = nil,
        links: [TrackerIssueRelation] = [],
        attachments: [String] = [],
        originalEstimateSeconds: Int? = nil,
        timeSpentSeconds: Int? = nil,
        remainingEstimateSeconds: Int? = nil,
        watchers: Int? = nil,
        isWatching: Bool? = nil
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
        self.fixVersions = fixVersions
        self.dueDate = dueDate
        self.resolution = resolution
        self.links = links
        self.attachments = attachments
        self.originalEstimateSeconds = originalEstimateSeconds
        self.timeSpentSeconds = timeSpentSeconds
        self.remainingEstimateSeconds = remainingEstimateSeconds
        self.watchers = watchers
        self.isWatching = isWatching
    }
}
