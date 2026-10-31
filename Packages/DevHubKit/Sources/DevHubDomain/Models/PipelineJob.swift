import Foundation

package struct PipelineJob: Hashable, Sendable {
    package let name: String
    package let stage: String?
    package let webURL: URL?
    package let id: String?
    package let status: CheckStatus
    package let duration: Int?
    package let allowsFailure: Bool
    package let failureMessage: String?

    package init(name: String, stage: String?, webURL: URL?, id: String? = nil, status: CheckStatus = .failed, duration: Int? = nil, allowsFailure: Bool = false, failureMessage: String? = nil) {
        self.name = name
        self.stage = stage
        self.webURL = webURL
        self.id = id
        self.status = status
        self.duration = duration
        self.allowsFailure = allowsFailure
        self.failureMessage = failureMessage
    }
}
