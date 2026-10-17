import Foundation

package struct PullRequestStatus: Hashable, Sendable {
    package let pullRequest: PullRequestInfo?
    package let pipeline: PipelineInfo?

    package init(pullRequest: PullRequestInfo?, pipeline: PipelineInfo?) {
        self.pullRequest = pullRequest
        self.pipeline = pipeline
    }
}
