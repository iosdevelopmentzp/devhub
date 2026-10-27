import Foundation

package struct PipelineJob: Hashable, Sendable {
    package let name: String
    package let stage: String?
    package let webURL: URL?
    package let id: String?
    package let status: CheckStatus

    package init(name: String, stage: String?, webURL: URL?, id: String? = nil, status: CheckStatus = .failed) {
        self.name = name
        self.stage = stage
        self.webURL = webURL
        self.id = id
        self.status = status
    }
}
