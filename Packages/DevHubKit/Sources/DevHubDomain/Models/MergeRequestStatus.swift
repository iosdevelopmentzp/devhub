import Foundation

package struct MergeRequestStatus: Hashable, Sendable {
    package let mergeRequest: MergeRequestInfo?
    package let pipeline: PipelineInfo?

    package init(mergeRequest: MergeRequestInfo?, pipeline: PipelineInfo?) {
        self.mergeRequest = mergeRequest
        self.pipeline = pipeline
    }
}
