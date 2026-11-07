import Foundation

package struct TrackerConfig: Codable, Hashable, Sendable {
    package var kind: TrackerKind? = nil
    package var project: String? = nil
    package var statuses: [String]? = nil
    package var startStatus: String? = nil
    package var filter: String? = nil
    package var branchFormat: String? = nil

    package init(
        kind: TrackerKind? = nil,
        project: String? = nil,
        statuses: [String]? = nil,
        startStatus: String? = nil,
        filter: String? = nil,
        branchFormat: String? = nil
    ) {
        self.kind = kind
        self.project = project
        self.statuses = statuses
        self.startStatus = startStatus
        self.filter = filter
        self.branchFormat = branchFormat
    }
}
