import Foundation
import DevHubDomain

struct PullRequestDetailActions {
    let toggleFile: (_ fileID: PullRequestFileDiff.ID) -> Void
    let toggleViewed: (_ fileID: PullRequestFileDiff.ID) -> Void
    let expandAllFiles: () -> Void
    let collapseAllFiles: () -> Void
    let showInDiff: (_ threadID: ReviewThread.ID) -> Void
    let toggleDiffThread: (_ threadID: ReviewThread.ID) -> Void
    let toggleThreadsInDiff: () -> Void
    let openAllDiffThreads: () -> Void
    let foldAllDiffThreads: () -> Void
    let openFile: (_ path: String, _ line: Int?) -> Void
    let resolveThread: (_ threadID: ReviewThread.ID) -> Void
    let reply: (_ threadID: ReviewThread.ID, _ body: String) -> Void
    let setCommentDraft: (_ text: String) -> Void
    let sendComment: (_ kind: PullRequestDetailStore.CommentKind) -> Void
    let startLineComment: (_ path: String, _ oldPath: String, _ line: DiffLineModel) -> Void
    let setLineCommentText: (_ text: String) -> Void
    let sendLineComment: () -> Void
    let cancelLineComment: () -> Void
    let cancelPipeline: () -> Void
    let fixThreads: () -> Void
    let runConfigAction: (_ actionID: ConfigActionItemModel.ID) -> Void
    let openWindow: (() -> Void)?
    let retry: () -> Void

    static let preview = PullRequestDetailActions(
        toggleFile: { _ in },
        toggleViewed: { _ in },
        expandAllFiles: {},
        collapseAllFiles: {},
        showInDiff: { _ in },
        toggleDiffThread: { _ in },
        toggleThreadsInDiff: {},
        openAllDiffThreads: {},
        foldAllDiffThreads: {},
        openFile: { _, _ in },
        resolveThread: { _ in },
        reply: { _, _ in },
        setCommentDraft: { _ in },
        sendComment: { _ in },
        startLineComment: { _, _, _ in },
        setLineCommentText: { _ in },
        sendLineComment: {},
        cancelLineComment: {},
        cancelPipeline: {},
        fixThreads: {},
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
            showInDiff: showInDiff,
            toggleDiffThread: toggleDiffThread,
            toggleThreadsInDiff: toggleThreadsInDiff,
            openAllDiffThreads: openAllDiffThreads,
            foldAllDiffThreads: foldAllDiffThreads,
            openFile: openFile,
            resolveThread: resolveThread,
            reply: reply,
            setCommentDraft: setCommentDraft,
            sendComment: sendComment,
            startLineComment: startLineComment,
            setLineCommentText: setLineCommentText,
            sendLineComment: sendLineComment,
            cancelLineComment: cancelLineComment,
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
        pullRequests: PullRequestsStore,
        appActions: AppActions,
        configActions: ConfigActionsStore,
        openWindow: ((PullRequestSummary) -> Void)?
    ) -> PullRequestDetailActions {
        let id = summary.id
        return PullRequestDetailActions(
            toggleFile: { detailStore.toggleFile($0, of: id) },
            toggleViewed: { detailStore.toggleViewed($0, of: id) },
            expandAllFiles: { detailStore.expandAllFiles(of: id) },
            collapseAllFiles: { detailStore.collapseAllFiles(of: id) },
            showInDiff: { detailStore.showInDiff(threadID: $0, of: id) },
            toggleDiffThread: { detailStore.toggleDiffThread($0) },
            toggleThreadsInDiff: { detailStore.toggleThreadsInDiff() },
            openAllDiffThreads: { detailStore.openAllDiffThreads(of: id) },
            foldAllDiffThreads: { detailStore.foldAllDiffThreads(of: id) },
            openFile: { appActions.openSourceFile(path: $0, line: $1, branch: summary.sourceBranch) },
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
            cancelPipeline: { pullRequests.perform(.cancelPipeline, on: id) },
            fixThreads: { appActions.fixThreadsWithClaude(summary) },
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
