import Foundation

package struct PipelineInfo: Hashable, Sendable {
    package let status: PipelineStatus
    package let webURL: URL?
    package let updatedAt: Date?
    package let id: Int?
    package let duration: Int?
    package let finishedAt: Date?
    package let failedJobCount: Int?

    package init(
        status: PipelineStatus,
        webURL: URL?,
        updatedAt: Date?,
        id: Int? = nil,
        duration: Int? = nil,
        finishedAt: Date? = nil,
        failedJobCount: Int? = nil
    ) {
        self.status = status
        self.webURL = webURL
        self.updatedAt = updatedAt
        self.id = id
        self.duration = duration
        self.finishedAt = finishedAt
        self.failedJobCount = failedJobCount
    }
}
