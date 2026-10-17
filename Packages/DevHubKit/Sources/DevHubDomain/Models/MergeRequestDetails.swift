import Foundation

package struct MergeRequestDetails: Hashable, Sendable {
    package let description: String
    package let threads: [MergeRequestThread]
    package let failedJobs: [PipelineJob]
    package let pipelineDuration: Int?

    package init(description: String, threads: [MergeRequestThread], failedJobs: [PipelineJob] = [], pipelineDuration: Int? = nil) {
        self.description = description
        self.threads = threads
        self.failedJobs = failedJobs
        self.pipelineDuration = pipelineDuration
    }
}
