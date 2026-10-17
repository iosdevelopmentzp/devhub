import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestDetailsMapper {

    static func model(
        summary: PullRequestSummary,
        details: PullRequestDetails?,
        diffs: [PullRequestFileDiff]?,
        error: String?,
        review: PullRequestReviewState
    ) -> PullRequestDetailsModel {
        if let error {
            return PullRequestDetailsModel(content: .failure(error))
        }
        guard let details, let diffs else { return PullRequestDetailsModel(content: .loading) }
        let additions = diffs.reduce(0) { $0 + $1.additions }
        let deletions = diffs.reduce(0) { $0 + $1.deletions }
        let viewedCount = diffs.filter { review.viewedFiles.contains($0.id) }.count
        let expandedCount = diffs.filter { review.expandedFiles.contains($0.id) }.count
        let threadRows = details.threads.map { PullRequestThreadRowMapper.model(for: $0, diffs: diffs, webURL: summary.webURL, isBusy: review.busyThreads.contains($0.id)) }
        return PullRequestDetailsModel(
            content: .loaded(
                PullRequestDetailsModel.Loaded(
                    pipelineTag: summary.pipeline.map { PullRequestTagMapper.pipelineTag($0, subject: "Pipeline of the last commit") },
                    pipelineURL: summary.pipeline?.webURL,
                    pipelineDurationText: (details.pipelineDuration ?? summary.pipeline?.duration).map { "took \(DurationFormat.text(TimeInterval($0)))" },
                    canCancelPipeline: summary.pipeline.map { $0.id != nil && PipelineStatePolicy.isActive($0.status) } ?? false,
                    failedJobs: details.failedJobs.map { PullRequestDetailsModel.JobLink(title: jobTitle($0), url: $0.webURL) },
                    description: description(details.description),
                    threadsTitle: details.threads.isEmpty ? "No open threads" : "Open threads \(details.threads.count)",
                    canFixThreads: details.threads.isEmpty == false && summary.state == .opened,
                    threads: threadRows,
                    filesTitle: "Files \(diffs.count) · +\(additions) −\(deletions)" + (viewedCount > 0 ? " · \(viewedCount) viewed" : ""),
                    canExpandAllFiles: diffs.count - viewedCount > expandedCount,
                    canCollapseAllFiles: expandedCount > 0,
                    hasThreadsInDiff: threadRows.contains { $0.canShowInDiff },
                    showsThreadsInDiff: review.showsThreadsInDiff,
                    files: diffs.map { PullRequestFileRowMapper.model(for: $0, review: review, threads: threadRows) }
                )
            )
        )
    }

    private static func jobTitle(_ job: PipelineJob) -> String {
        job.stage.map { "\(job.name) (\($0))" } ?? job.name
    }

    private static func description(_ text: String) -> AttributedString? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: trimmed, options: options)) ?? AttributedString(trimmed)
    }
}
