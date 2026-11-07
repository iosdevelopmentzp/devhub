import Foundation

package struct TrackerSettings: Hashable, Sendable {
    package var kind: TrackerKind
    package var project: String?
    package var statuses: [String]
    package var startStatus: String
    package var filter: String?
    package var branchFormat: String

    package static let standard = TrackerSettingsPolicy.settings(for: ProjectConfig())

    package init(kind: TrackerKind, project: String?, statuses: [String], startStatus: String, filter: String?, branchFormat: String) {
        self.kind = kind
        self.project = project
        self.statuses = statuses
        self.startStatus = startStatus
        self.filter = filter
        self.branchFormat = branchFormat
    }
}
