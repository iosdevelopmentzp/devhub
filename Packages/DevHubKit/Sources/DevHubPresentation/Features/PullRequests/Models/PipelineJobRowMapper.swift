import Foundation
import DevHubDomain
import DevHubUI

enum PipelineJobRowMapper {
    static func rows(for jobs: [PipelineJob], review: PullRequestReviewState, words: CodeHostWords) -> [PipelineJobRowModel] {
        jobs.enumerated()
            .sorted { (rank($0.element.status), $0.offset) < (rank($1.element.status), $1.offset) }
            .map { model(for: $0.element, index: $0.offset, review: review, words: words) }
    }

    static func title(for jobs: [PipelineJob], words: CodeHostWords) -> String {
        let failed = jobs.filter { $0.status == .failed }.count
        let running = jobs.filter { $0.status == .running }.count
        let parts = ["\(words.checksTitle) \(jobs.count)", failed > 0 ? "\(failed) failed" : nil, running > 0 ? "\(running) running" : nil]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }

    static func model(for job: PipelineJob, index: Int, review: PullRequestReviewState, words: CodeHostWords) -> PipelineJobRowModel {
        let key = job.id ?? "\(index):\(job.name)"
        let isFinished = [.running, .pending, .created, .preparing, .waitingForResource, .scheduled].contains(job.status) == false
        return PipelineJobRowModel(
            id: key,
            jobID: job.id,
            title: job.stage.map { "\(job.name) (\($0))" } ?? job.name,
            icon: PullRequestTagMapper.pipelineIcon(job.status),
            tint: PullRequestTagMapper.pipelineTint(job.status),
            statusText: words.status(job.status),
            url: job.webURL,
            canShowLog: job.id != nil && isFinished && job.status != .skipped,
            isLogOpen: job.id.map(review.openJobLogs.contains) ?? false,
            log: job.id.flatMap { review.jobLogs[$0] },
            canRetry: job.id != nil && [.failed, .canceled].contains(job.status),
            retryHint: "Run this \(words.job) again",
            isBusy: job.id.map(review.busyJobs.contains) ?? false
        )
    }

    private static func rank(_ status: CheckStatus) -> Int {
        switch status {
        case .failed: 0
        case .running: 1
        case .canceled: 2
        case .pending, .created, .preparing, .waitingForResource, .scheduled, .manual: 3
        case .success: 5
        default: 4
        }
    }
}
