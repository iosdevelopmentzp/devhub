import Foundation
import DevHubDomain

struct PullRequestDetailActions {
    let toggleFile: (_ fileID: PullRequestFileDiff.ID) -> Void
    let toggleViewed: (_ fileID: PullRequestFileDiff.ID) -> Void
    let expandAllFiles: (_ fileIDs: Set<PullRequestFileDiff.ID>) -> Void
    let collapseAllFiles: () -> Void
    let toggleHiddenFiles: () -> Void
    let toggleOnlyChangedSinceReview: () -> Void
    let forgetReview: () -> Void
    let togglePerson: (_ login: String, _ role: PullRequestPersonRole) -> Void
    let explain: (AIProvider) -> Void
    let stopExplain: () -> Void
    let hideExplanation: () -> Void
    let hideFiles: (_ paths: [String]) -> Void
    let unhideFile: (_ path: String) -> Void
    let showInDiff: (_ threadID: ReviewThread.ID) -> Void
    let toggleDiffThread: (_ threadID: ReviewThread.ID) -> Void
    let toggleThreadsInDiff: () -> Void
    let openAllDiffThreads: () -> Void
    let foldAllDiffThreads: () -> Void
    let openFile: (_ path: String, _ line: Int?) -> Void
    let openFileOnWeb: (_ path: String, _ line: Int?) -> Void
    let toggleFullFile: (_ fileID: PullRequestFileDiff.ID) -> Void
    let resolveThread: (_ threadID: ReviewThread.ID) -> Void
    let reply: (_ threadID: ReviewThread.ID, _ body: String) -> Void
    let setCommentDraft: (_ text: String) -> Void
    let sendComment: (_ kind: PullRequestDetailStore.CommentKind) -> Void
    let startLineComment: (_ path: String, _ oldPath: String, _ line: DiffLineModel) -> Void
    let setLineCommentText: (_ text: String) -> Void
    let sendLineComment: () -> Void
    let cancelLineComment: () -> Void
    let toggleJobLog: (_ jobID: String) -> Void
    let toggleJobDetails: (_ key: String) -> Void
    let toggleTestMessage: (_ testID: String) -> Void
    let toggleCIHistoryRun: (_ workflowID: String) -> Void
    let retryJob: (_ jobID: String, _ name: String) -> Void
    let approveJob: (_ jobID: String, _ name: String) -> Void
    let rerunWorkflow: (_ workflowID: String, _ fromFailed: Bool) -> Void
    let cancelWorkflow: (_ workflowID: String) -> Void
    let runCISetup: (_ command: String) -> Void
    let startAutoRerun: (_ maxAttempts: Int) -> Void
    let stopAutoRerun: () -> Void
    let toggleCIHistory: () -> Void
    let clearCIHistory: () -> Void
    let cancelPipeline: () -> Void
    let fixThreads: (AIProvider) -> Void
    let runConfigAction: (_ actionID: ConfigActionItemModel.ID) -> Void
    let openWindow: (() -> Void)?
    let retry: () -> Void

    static let preview = PullRequestDetailActions(
        toggleFile: { _ in },
        toggleViewed: { _ in },
        expandAllFiles: { _ in },
        collapseAllFiles: {},
        toggleHiddenFiles: {},
        toggleOnlyChangedSinceReview: {},
        forgetReview: {},
        togglePerson: { _, _ in },
        explain: { _ in },
        stopExplain: {},
        hideExplanation: {},
        hideFiles: { _ in },
        unhideFile: { _ in },
        showInDiff: { _ in },
        toggleDiffThread: { _ in },
        toggleThreadsInDiff: {},
        openAllDiffThreads: {},
        foldAllDiffThreads: {},
        openFile: { _, _ in },
        openFileOnWeb: { _, _ in },
        toggleFullFile: { _ in },
        resolveThread: { _ in },
        reply: { _, _ in },
        setCommentDraft: { _ in },
        sendComment: { _ in },
        startLineComment: { _, _, _ in },
        setLineCommentText: { _ in },
        sendLineComment: {},
        cancelLineComment: {},
        toggleJobLog: { _ in },
        toggleJobDetails: { _ in },
        toggleTestMessage: { _ in },
        toggleCIHistoryRun: { _ in },
        retryJob: { _, _ in },
        approveJob: { _, _ in },
        rerunWorkflow: { _, _ in },
        cancelWorkflow: { _ in },
        runCISetup: { _ in },
        startAutoRerun: { _ in },
        stopAutoRerun: {},
        toggleCIHistory: {},
        clearCIHistory: {},
        cancelPipeline: {},
        fixThreads: { _ in },
        runConfigAction: { _ in },
        openWindow: {},
        retry: {}
    )

    var withoutWindow: PullRequestDetailActions {
        PullRequestDetailActions(
            toggleFile: toggleFile,
            toggleViewed: toggleViewed,
            expandAllFiles: expandAllFiles,
            collapseAllFiles: collapseAllFiles,
            toggleHiddenFiles: toggleHiddenFiles,
            toggleOnlyChangedSinceReview: toggleOnlyChangedSinceReview,
            forgetReview: forgetReview,
            togglePerson: togglePerson,
            explain: explain,
            stopExplain: stopExplain,
            hideExplanation: hideExplanation,
            hideFiles: hideFiles,
            unhideFile: unhideFile,
            showInDiff: showInDiff,
            toggleDiffThread: toggleDiffThread,
            toggleThreadsInDiff: toggleThreadsInDiff,
            openAllDiffThreads: openAllDiffThreads,
            foldAllDiffThreads: foldAllDiffThreads,
            openFile: openFile,
            openFileOnWeb: openFileOnWeb,
            toggleFullFile: toggleFullFile,
            resolveThread: resolveThread,
            reply: reply,
            setCommentDraft: setCommentDraft,
            sendComment: sendComment,
            startLineComment: startLineComment,
            setLineCommentText: setLineCommentText,
            sendLineComment: sendLineComment,
            cancelLineComment: cancelLineComment,
            toggleJobLog: toggleJobLog,
            toggleJobDetails: toggleJobDetails,
            toggleTestMessage: toggleTestMessage,
            toggleCIHistoryRun: toggleCIHistoryRun,
            retryJob: retryJob,
            approveJob: approveJob,
            rerunWorkflow: rerunWorkflow,
            cancelWorkflow: cancelWorkflow,
            runCISetup: runCISetup,
            startAutoRerun: startAutoRerun,
            stopAutoRerun: stopAutoRerun,
            toggleCIHistory: toggleCIHistory,
            clearCIHistory: clearCIHistory,
            cancelPipeline: cancelPipeline,
            fixThreads: fixThreads,
            runConfigAction: runConfigAction,
            openWindow: nil,
            retry: retry
        )
    }
}

extension PullRequestDetailActions {
    @MainActor
    static func live(
        for summary: PullRequestSummary,
        detailStore: PullRequestDetailStore,
        people: PullRequestPeopleStore,
        aiText: AITextStore,
        autoRerun: CIAutoRerunStore,
        pullRequests: PullRequestsStore,
        appActions: AppActions,
        configActions: ConfigActionsStore,
        openWindow: ((PullRequestSummary) -> Void)?
    ) -> PullRequestDetailActions {
        let id = summary.id
        return PullRequestDetailActions(
            toggleFile: { detailStore.toggleFile($0, of: id) },
            toggleViewed: { detailStore.toggleViewed($0, of: id) },
            expandAllFiles: { detailStore.expandAllFiles($0, of: id) },
            collapseAllFiles: { detailStore.collapseAllFiles(of: id) },
            toggleHiddenFiles: { detailStore.toggleHiddenFiles(of: id) },
            toggleOnlyChangedSinceReview: { detailStore.toggleOnlyChangedSinceReview(of: id) },
            forgetReview: { detailStore.forgetReview(of: id) },
            togglePerson: { people.toggle($0, role: $1, on: summary) },
            explain: { provider in
                aiText.explain(summary, description: detailStore.details[id]?.description ?? "", files: detailStore.diffs[id] ?? [], changedSinceReview: detailStore.review(of: id).changedSinceReview, provider: provider)
            },
            stopExplain: { aiText.stop(.explain(iid: id)) },
            hideExplanation: { aiText.clearExplanation(of: id) },
            hideFiles: { detailStore.hideFiles($0) },
            unhideFile: { detailStore.unhideFile($0) },
            showInDiff: { detailStore.showInDiff(threadID: $0, of: id) },
            toggleDiffThread: { detailStore.toggleDiffThread($0) },
            toggleThreadsInDiff: { detailStore.toggleThreadsInDiff() },
            openAllDiffThreads: { detailStore.openAllDiffThreads(of: id) },
            foldAllDiffThreads: { detailStore.foldAllDiffThreads(of: id) },
            openFile: { appActions.openSourceFile(path: $0, line: $1, branch: summary.sourceBranch) },
            openFileOnWeb: { appActions.open(detailStore.fileWebURL(path: $0, line: $1, of: summary)) },
            toggleFullFile: { detailStore.toggleFullFile($0, of: summary) },
            resolveThread: { detailStore.resolveThread($0, of: id) },
            reply: { detailStore.reply($1, to: $0, of: id) },
            setCommentDraft: { detailStore.setCommentDraft($0, of: id) },
            sendComment: { detailStore.send($0, on: id) },
            startLineComment: { path, oldPath, line in
                detailStore.startLineComment(path: path, oldPath: oldPath, lineID: line.id, newLine: line.newNumber, oldLine: line.oldNumber, of: id)
            },
            setLineCommentText: { detailStore.setLineCommentText($0) },
            sendLineComment: { detailStore.sendLineComment(headSHA: summary.headSHA) },
            cancelLineComment: { detailStore.cancelLineComment() },
            toggleJobLog: { detailStore.toggleJobLog($0) },
            toggleJobDetails: { detailStore.toggleJobDetails($0) },
            toggleTestMessage: { detailStore.toggleTestMessage($0) },
            toggleCIHistoryRun: { detailStore.toggleCIHistoryRun($0) },
            retryJob: { detailStore.retryJob($0, named: $1, of: id) },
            approveJob: { detailStore.approveJob($0, named: $1, of: id) },
            rerunWorkflow: { detailStore.rerunWorkflow($0, fromFailed: $1, of: id) },
            cancelWorkflow: { detailStore.cancelWorkflow($0, of: id) },
            runCISetup: { appActions.runInTerminal($0, at: detailStore.ciCheckoutPath, title: "Started the CircleCI setup in Terminal") },
            startAutoRerun: { autoRerun.start(id, maxAttempts: $0) },
            stopAutoRerun: { autoRerun.stop(id) },
            toggleCIHistory: { detailStore.toggleCIHistory(of: id) },
            clearCIHistory: { detailStore.clearCIHistory(of: id) },
            cancelPipeline: { pullRequests.perform(.cancelPipeline, on: id) },
            fixThreads: { appActions.fixThreads(with: $0, summary) },
            runConfigAction: { actionID in
                configActions.request(
                    id: actionID,
                    item: ActionItemContext(branch: summary.sourceBranch, rowID: String(id), pullRequestNumber: id, pullRequestURL: summary.webURL),
                    slot: Placement.pullRequestsRow.slot(for: String(id))
                )
            },
            openWindow: openWindow.map { open in { open(summary) } },
            retry: { Task { await detailStore.reload(id) } }
        )
    }
}
