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
        let paths = diffs.map(\.path)
        let hidden = HiddenFilePolicy.hiddenPaths(in: paths, patterns: context.hiddenFiles, chosen: review.chosenHiddenFiles)
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
                    autoRerun: autoRerun(review: review),
                    ciHistoryTitle: review.ciHistory.isEmpty ? nil : "Previous CircleCI runs \(review.ciHistory.count)",
                    showsCIHistory: review.showsCIHistory,
                    ciHistory: review.ciHistory.map { CIHistoryRowMapper.model(for: $0, flaky: review.ciFlakyTests, isOpen: review.openCIHistoryRuns.contains($0.id), openTestMessages: review.openTestMessages, words: words) },
                    reviewLines: PullRequestReviewMapper.lines(for: summary, username: context.username, words: words),
                    description: description(details.description),
                    threadsTitle: details.threads.isEmpty ? "No open threads" : "Open threads \(details.threads.count)",
                    canFixThreads: details.threads.isEmpty == false && summary.state == .opened,
                    threads: threadRows,
                    commentBox: commentBox(summary: summary, review: review, words: words),
                    filesTitle: "Files \(visible.count) · +\(additions) −\(deletions)" + (viewedCount > 0 ? " · \(viewedCount) viewed" : ""),
                    hiddenFilesTitle: hiddenFilesTitle(count: hidden.count, shown: review.showsHiddenFiles),
                    hiddenFilesHint: hidden.isEmpty ? nil : hiddenFilesHint(count: hidden.count, shown: review.showsHiddenFiles),
                    hideSuggestion: hideSuggestion(HiddenFilePolicy.suggestedPaths(in: paths, hidden: hidden)),
                    showsHiddenFiles: review.showsHiddenFiles,
                    canExpandAllFiles: visible.count - viewedCount > expandedCount,
                    canCollapseAllFiles: expandedCount > 0,
                    hasThreadsInDiff: threadRows.contains { $0.canShowInDiff },
                    showsThreadsInDiff: review.showsThreadsInDiff,
                    files: visible.map { file in
                        PullRequestFileRowMapper.hiding(
                            PullRequestFileRowMapper.model(for: file, review: review, threads: threadRows, words: words),
                            isHidden: hidden.contains(file.path),
                            isChosen: review.chosenHiddenFiles.contains(file.path)
                        )
                    }
                )
            )
        )
    }

    static func autoRerun(review: PullRequestReviewState) -> PullRequestDetailsModel.AutoRerun? {
        if let plan = review.autoRerunPlan {
            return PullRequestDetailsModel.AutoRerun(
                isOn: true,
                title: "Auto re-run \(plan.attempts) of \(plan.maxAttempts)",
                icon: "repeat.circle.fill",
                hint: "DevHub runs the failed CircleCI jobs again each time a workflow fails. \(CountText.count(plan.attemptsLeft, "re-run", "re-runs")) left. Click to stop.",
                choices: []
            )
        }
        guard review.hasCIProvider, let state = review.ciToolState, CIPolicy.installCommand(for: state) == nil else { return nil }
        return PullRequestDetailsModel.AutoRerun(
            isOn: false,
            title: "Auto re-run",
            icon: "repeat.circle",
            hint: "Run the failed CircleCI jobs again each time a workflow fails (circleci workflow rerun --from-failed). DevHub checks every minute and tells you when the checks pass or when it gives up.",
            choices: CIAutoRerunPolicy.attemptChoices.map { PullRequestDetailsModel.AutoRerun.Choice(count: $0, title: "Up to \(CountText.count($0, "time", "times"))") }
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

    static func hideSuggestion(_ paths: [String]) -> PullRequestDetailsModel.HideSuggestion? {
        guard paths.isEmpty == false else { return nil }
        let names = paths.prefix(3).map { ($0 as NSString).lastPathComponent }
        let rest = paths.count > 3 ? " and \(paths.count - 3) more" : ""
        return PullRequestDetailsModel.HideSuggestion(
            text: "\(CountText.count(paths.count, "file")) \(paths.count == 1 ? "looks" : "look") like tests, project files or lock files",
            actionTitle: paths.count == 1 ? "Hide It" : "Hide Them",
            hint: "Hide \(names.joined(separator: ", "))\(rest) in the requests of this project. \"Show N hidden\" lists them again.",
            paths: paths
        )
    }

    private static func hiddenFilesTitle(count: Int, shown: Bool) -> String? {
        guard count > 0 else { return nil }
        return shown ? "Hide \(count)" : "Show \(count) hidden"
    }

    private static func hiddenFilesHint(count: Int, shown: Bool) -> String {
        let reason = count == 1
            ? "1 file is hidden: you hid it, or it matches git.pullRequests.hiddenFiles."
            : "\(count) files are hidden: you hid them, or they match git.pullRequests.hiddenFiles."
        return shown ? "\(reason) Click to hide them again." : "\(reason) Click to show them."
    }

    private static func jobTitle(_ job: PipelineJob) -> String {
        job.stage.map { "\(job.name) (\($0))" } ?? job.name
    }

    private static func description(_ text: String) -> AttributedString? {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        return CommentText.attributed(text)
    }
}
