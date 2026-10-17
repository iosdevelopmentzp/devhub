import Foundation
import DevHubDomain

struct MergeRequestDetailActions {
    let toggleFile: (_ fileID: MergeRequestFileDiff.ID) -> Void
    let toggleViewed: (_ fileID: MergeRequestFileDiff.ID) -> Void
    let expandAllFiles: () -> Void
    let collapseAllFiles: () -> Void
    let showInDiff: (_ threadID: MergeRequestThread.ID) -> Void
    let toggleDiffThread: (_ threadID: MergeRequestThread.ID) -> Void
    let toggleThreadsInDiff: () -> Void
    let openAllDiffThreads: () -> Void
    let foldAllDiffThreads: () -> Void
    let openFile: (_ path: String, _ line: Int?) -> Void
    let resolveThread: (_ threadID: MergeRequestThread.ID) -> Void
    let reply: (_ threadID: MergeRequestThread.ID, _ body: String) -> Void
    let cancelPipeline: () -> Void
    let fixThreads: () -> Void
    let openWindow: (() -> Void)?
    let retry: () -> Void

    static let preview = MergeRequestDetailActions(
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
        cancelPipeline: {},
        fixThreads: {},
        openWindow: {},
        retry: {}
    )

    var withoutWindow: MergeRequestDetailActions {
        MergeRequestDetailActions(
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
            cancelPipeline: cancelPipeline,
            fixThreads: fixThreads,
            openWindow: nil,
            retry: retry
        )
    }
}

extension MergeRequestDetailActions {
    @MainActor
    static func live(
        for summary: MergeRequestSummary,
        detailStore: MergeRequestDetailStore,
        gitLab: GitLabStore,
        appActions: AppActions,
        openWindow: ((MergeRequestSummary) -> Void)?
    ) -> MergeRequestDetailActions {
        let id = summary.id
        return MergeRequestDetailActions(
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
            cancelPipeline: { gitLab.perform(.cancelPipeline, on: id) },
            fixThreads: { appActions.fixThreadsWithClaude(summary) },
            openWindow: openWindow.map { open in { open(summary) } },
            retry: { Task { await detailStore.reload(id) } }
        )
    }
}
