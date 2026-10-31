import Foundation
import DevHubDomain
import DevHubUI

enum PullRequestDetailsMapper {

    static func model(
        summary: PullRequestSummary,
        details: PullRequestDetails?,
        diffs: [PullRequestFileDiff]?,
        error: String?,
        review: PullRequestReviewState,
        context: PullRequestRowContext
    ) -> PullRequestDetailsModel {
        if let error {
            return PullRequestDetailsModel(content: .failure(error))
        }
        guard let details, let diffs else { return PullRequestDetailsModel(content: .loading) }
        let words = context.words
        let hidden = HiddenFilePolicy.hiddenPaths(in: diffs.map(\.path), patterns: context.hiddenFiles)
        let visible = review.showsHiddenFiles ? diffs : diffs.filter { hidden.contains($0.path) == false }
        let additions = visible.reduce(0) { $0 + $1.additions }
        let deletions = visible.reduce(0) { $0 + $1.deletions }
        let viewedCount = visible.filter { review.viewedFiles.contains($0.id) }.count
        let expandedCount = visible.filter { review.expandedFiles.contains($0.id) }.count
        let threadRows = details.threads.map { ReviewThreadRowMapper.model(for: $0, diffs: visible, webURL: summary.webURL, isBusy: review.busyThreads.contains($0.id)) }
        return PullRequestDetailsModel(
            content: .loaded(
                PullRequestDetailsModel.Loaded(
                    pipelineTag: summary.pipeline.map { PullRequestTagMapper.pipelineTag($0, subject: "\(words.checksTitle) of the last commit", words: words) },
                    pipelineURL: summary.pipeline?.webURL,
                    pipelineDurationText: (details.pipelineDuration ?? summary.pipeline?.duration).map { "took \(DurationFormat.text(TimeInterval($0)))" },
                    canCancelPipeline: summary.pipeline.map { $0.id != nil && PipelineStatePolicy.isActive($0.status) } ?? false,
                    ciNotice: ciNotice(review: review),
                    failedJobs: details.jobs.isEmpty ? details.failedJobs.map { PullRequestDetailsModel.JobLink(title: jobTitle($0), url: $0.webURL) } : [],
                    jobsTitle: PipelineJobRowMapper.title(for: details.jobs, words: words),
                    jobGroups: PipelineJobRowMapper.groups(for: details.jobs, review: review, words: words),
                    reviewLines: PullRequestReviewMapper.lines(for: summary, username: context.username, words: words),
                    description: description(details.description),
                    threadsTitle: details.threads.isEmpty ? "No open threads" : "Open threads \(details.threads.count)",
                    canFixThreads: details.threads.isEmpty == false && summary.state == .opened,
                    threads: threadRows,
                    commentBox: commentBox(summary: summary, review: review, words: words),
                    filesTitle: "Files \(visible.count) · +\(additions) −\(deletions)" + (viewedCount > 0 ? " · \(viewedCount) viewed" : ""),
                    hiddenFilesTitle: hiddenFilesTitle(count: hidden.count, shown: review.showsHiddenFiles),
                    hiddenFilesHint: hidden.isEmpty ? nil : hiddenFilesHint(count: hidden.count, shown: review.showsHiddenFiles),
                    showsHiddenFiles: review.showsHiddenFiles,
                    canExpandAllFiles: visible.count - viewedCount > expandedCount,
                    canCollapseAllFiles: expandedCount > 0,
                    hasThreadsInDiff: threadRows.contains { $0.canShowInDiff },
                    showsThreadsInDiff: review.showsThreadsInDiff,
                    files: visible.map { PullRequestFileRowMapper.model(for: $0, review: review, threads: threadRows, words: words) }
                )
            )
        )
    }

    static func commentBox(summary: PullRequestSummary, review: PullRequestReviewState, words: CodeHostWords) -> PullRequestCommentBoxModel {
        let reference = words.reference(summary.iid)
        let hasText = review.commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return PullRequestCommentBoxModel(
            draft: review.commentDraft,
            placeholder: "Comment on \(reference)…",
            isBusy: review.isCommentBusy,
            canSend: hasText && review.isCommentBusy == false,
            canRequestChanges: summary.permissions.canRequestChanges && summary.state == .opened,
            requestChangesHint: "Send the comment as a review that asks for changes before \(reference) can merge"
        )
    }

    static func ciNotice(review: PullRequestReviewState) -> PullRequestDetailsModel.CINotice? {
        guard review.hasCIProvider, let state = review.ciToolState, let command = CIPolicy.installCommand(for: state) else { return nil }
        let text: String
        if state.isInstalled == false {
            text = "The circleci tool is not installed, so the CircleCI jobs show as links only."
        } else if let version = state.version, CIPolicy.isSupported(version: version) == false {
            text = "The circleci tool is version \(version); DevHub needs 1.0 or newer for the CircleCI jobs."
        } else {
            text = "The circleci tool is not logged in, so the CircleCI jobs show as links only."
        }
        return PullRequestDetailsModel.CINotice(text: text, command: command)
    }

    private static func hiddenFilesTitle(count: Int, shown: Bool) -> String? {
        guard count > 0 else { return nil }
        return shown ? "Hide \(count)" : "Show \(count) hidden"
    }

    private static func hiddenFilesHint(count: Int, shown: Bool) -> String {
        let files = CountText.count(count, "file")
        return shown
            ? "\(files) match git.pullRequests.hiddenFiles (tests, project files, lock files by default). Click to hide them again."
            : "\(files) match git.pullRequests.hiddenFiles (tests, project files, lock files by default) and stay hidden until you show them. Click to show them."
    }

    private static func jobTitle(_ job: PipelineJob) -> String {
        job.stage.map { "\(job.name) (\($0))" } ?? job.name
    }

    private static func description(_ text: String) -> AttributedString? {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        return CommentText.attributed(text)
    }
}
