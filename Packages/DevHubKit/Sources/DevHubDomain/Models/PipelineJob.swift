import Foundation

package struct PipelineJob: Hashable, Sendable {
    package let name: String
    package let stage: String?
    package let webURL: URL?

    package init(name: String, stage: String?, webURL: URL?) {
        self.name = name
        self.stage = stage
        self.webURL = webURL
    }
}
