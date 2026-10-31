import Foundation
import DevHubDomain
import DevHubUI

enum PipelineJobRowMapper {
    static func groups(for jobs: [PipelineJob], review: PullRequestReviewState, words: CodeHostWords) -> [PipelineJobGroupModel] {
        var order: [String] = []
        var members: [String: [(offset: Int, job: PipelineJob)]] = [:]
        for (offset, job) in jobs.enumerated() {
            let key = job.stage ?? ""
            if members[key] == nil {
                order.append(key)
            }
            members[key, default: []].append((offset, job))
        }
        let showsTitles = order.contains { $0.isEmpty == false }
        return order.map { key in
            let group = members[key] ?? []
            let rows = group
                .sorted { (rank($0.job.status), $0.offset) < (rank($1.job.status), $1.offset) }
                .map { model(for: $0.job, index: $0.offset, review: review, words: words) }
            let status = groupStatus(group.map(\.job))
            return PipelineJobGroupModel(
                id: key.isEmpty ? "-" : key,
                title: showsTitles ? (key.isEmpty ? "other" : key) : nil,
                icon: PullRequestTagMapper.pipelineIcon(status),
                tint: PullRequestTagMapper.pipelineTint(status),
                statusText: counts(for: group.map(\.job), words: words) ?? words.status(status),
                jobs: rows
            )
        }
    }

    static func title(for jobs: [PipelineJob], words: CodeHostWords) -> String {
        (["\(words.checksTitle) \(jobs.count)"] + [counts(for: jobs, words: words)].compactMap { $0 }).joined(separator: " · ")
    }

    static func model(for job: PipelineJob, index: Int, review: PullRequestReviewState, words: CodeHostWords) -> PipelineJobRowModel {
        let key = job.id ?? "\(index):\(job.name)"
        let isFinished = [.running, .pending, .created, .preparing, .waitingForResource, .scheduled].contains(job.status) == false
        let failedButAllowed = job.status == .failed && job.allowsFailure
        return PipelineJobRowModel(
            id: key,
            jobID: job.id,
            title: job.name,
            icon: PullRequestTagMapper.pipelineIcon(job.status),
            tint: failedButAllowed ? .orange : PullRequestTagMapper.pipelineTint(job.status),
            statusText: words.status(job.status),
            durationText: job.duration.map { DurationFormat.text(TimeInterval($0)) },
            allowedToFailText: job.allowsFailure ? "allowed to fail" : nil,
            failureText: job.failureMessage,
            url: job.webURL,
            canShowLog: job.id != nil && isFinished && job.status != .skipped,
            isLogOpen: job.id.map(review.openJobLogs.contains) ?? false,
            log: job.id.flatMap { review.jobLogs[$0] },
            canRetry: job.id != nil && [.failed, .canceled].contains(job.status),
            retryHint: "Run this \(words.job) again",
            isBusy: job.id.map(review.busyJobs.contains) ?? false
        )
    }

    private static func counts(for jobs: [PipelineJob], words: CodeHostWords) -> String? {
        let failed = jobs.filter { $0.status == .failed && $0.allowsFailure == false }.count
        let running = jobs.filter { $0.status == .running }.count
        let parts = [failed > 0 ? "\(failed) failed" : nil, running > 0 ? "\(running) running" : nil].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func groupStatus(_ jobs: [PipelineJob]) -> CheckStatus {
        if jobs.contains(where: { $0.status == .failed && $0.allowsFailure == false }) { return .failed }
        if jobs.contains(where: { $0.status == .running }) { return .running }
        if jobs.contains(where: { [.pending, .created, .preparing, .waitingForResource, .scheduled].contains($0.status) }) { return .pending }
        if jobs.contains(where: { $0.status == .canceled }) { return .canceled }
        return .success
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
