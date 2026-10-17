import Foundation

package struct PullRequestDetails: Hashable, Sendable {
    package let description: String
    package let threads: [PullRequestThread]
    package let failedJobs: [PipelineJob]
    package let pipelineDuration: Int?

    package init(description: String, threads: [PullRequestThread], failedJobs: [PipelineJob] = [], pipelineDuration: Int? = nil) {
        self.description = description
        self.threads = threads
        self.failedJobs = failedJobs
        self.pipelineDuration = pipelineDuration
    }
}
