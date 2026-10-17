import Foundation

package struct PullRequestDetails: Hashable, Sendable {
    package let description: String
    package let threads: [ReviewThread]
    package let failedJobs: [PipelineJob]
    package let pipelineDuration: Int?

    package init(description: String, threads: [ReviewThread], failedJobs: [PipelineJob] = [], pipelineDuration: Int? = nil) {
        self.description = description
        self.threads = threads
        self.failedJobs = failedJobs
        self.pipelineDuration = pipelineDuration
    }
}
