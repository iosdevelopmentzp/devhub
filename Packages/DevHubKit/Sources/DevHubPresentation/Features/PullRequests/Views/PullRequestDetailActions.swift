import Foundation
import DevHubDomain

struct PullRequestDetailActions {
    let toggleFile: (_ fileID: PullRequestFileDiff.ID) -> Void
    let toggleViewed: (_ fileID: PullRequestFileDiff.ID) -> Void
    let expandAllFiles: (_ fileIDs: Set<PullRequestFileDiff.ID>) -> Void
    let collapseAllFiles: () -> Void
    let toggleHiddenFiles: () -> Void
    let toggleFileGroup: (_ name: String) -> Void
    let setDiffLayout: (DiffLayout) -> Void
    let toggleFileLayout: (_ fileID: PullRequestFileDiff.ID) -> Void
    let changeDiffFontSize: (_ step: Int) -> Void
    let resetDiffFontSize: () -> Void
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
    let setFindQuery: (_ query: String) -> Void
    let stepFind: (_ offset: Int, _ matches: [DiffFindMatch]) -> Void
    let endFind: () -> Void
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
    let toggleJobArtifacts: (_ jobID: String) -> Void
    let downloadArtifacts: (_ jobID: String, _ name: String) -> Void
    let runCISetup: (_ command: String) -> Void
    let startAutoRerun: (_ maxAttempts: Int) -> Void
    let stopAutoRerun: () -> Void
    let setAutoRerunOnlyFlaky: (_ enabled: Bool) -> Void
    let copyCIDiagnostics: () -> Void
    let saveCIDiagnostics: () -> Void
    let toggleCIHistory: () -> Void
    let clearCIHistory: () -> Void
    let cancelPipeline: () -> Void
    let fixThreads: (AIProvider) -> Void
    let runConfigAction: (_ actionID: ConfigActionItemModel.ID) -> Void
    let openWindow: (() -> Void)?
    let refresh: () -> Void
    let retry: () -> Void

    static let preview = PullRequestDetailActions(
        toggleFile: { _ in },
        toggleViewed: { _ in },
        expandAllFiles: { _ in },
        collapseAllFiles: {},
        toggleHiddenFiles: {},
        toggleFileGroup: { _ in },
        setDiffLayout: { _ in },
        toggleFileLayout: { _ in },
        changeDiffFontSize: { _ in },
        resetDiffFontSize: {},
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
        setFindQuery: { _ in },
        stepFind: { _, _ in },
        endFind: {},
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
        toggleJobArtifacts: { _ in },
        downloadArtifacts: { _, _ in },
        runCISetup: { _ in },
        startAutoRerun: { _ in },
        stopAutoRerun: {},
        setAutoRerunOnlyFlaky: { _ in },
        copyCIDiagnostics: {},
        saveCIDiagnostics: {},
        toggleCIHistory: {},
        clearCIHistory: {},
        cancelPipeline: {},
        fixThreads: { _ in },
        runConfigAction: { _ in },
        openWindow: {},
        refresh: {},
        retry: {}
    )

    var withoutWindow: PullRequestDetailActions {
        PullRequestDetailActions(
            toggleFile: toggleFile,
            toggleViewed: toggleViewed,
            expandAllFiles: expandAllFiles,
            collapseAllFiles: collapseAllFiles,
            toggleHiddenFiles: toggleHiddenFiles,
            toggleFileGroup: toggleFileGroup,
            setDiffLayout: setDiffLayout,
            toggleFileLayout: toggleFileLayout,
            changeDiffFontSize: changeDiffFontSize,
            resetDiffFontSize: resetDiffFontSize,
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
            setFindQuery: setFindQuery,
            stepFind: stepFind,
            endFind: endFind,
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
            toggleJobArtifacts: toggleJobArtifacts,
            downloadArtifacts: downloadArtifacts,
            runCISetup: runCISetup,
            startAutoRerun: startAutoRerun,
            stopAutoRerun: stopAutoRerun,
            setAutoRerunOnlyFlaky: setAutoRerunOnlyFlaky,
            copyCIDiagnostics: copyCIDiagnostics,
            saveCIDiagnostics: saveCIDiagnostics,
            toggleCIHistory: toggleCIHistory,
            clearCIHistory: clearCIHistory,
            cancelPipeline: cancelPipeline,
            fixThreads: fixThreads,
            runConfigAction: runConfigAction,
            openWindow: nil,
            refresh: refresh,
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
        diagnostics: CIDiagnosticsStore,
        pullRequests: PullRequestsStore,
        settings: SettingsStore,
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
            toggleFileGroup: { detailStore.toggleFileGroup($0, of: id) },
            setDiffLayout: { pullRequests.diffLayout = $0 },
            toggleFileLayout: { detailStore.toggleFileLayout($0, of: id, standard: pullRequests.diffLayout) },
            changeDiffFontSize: { settings.changeDiffFontSize(by: $0) },
            resetDiffFontSize: { settings.resetDiffFontSize() },
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
            setFindQuery: { detailStore.setFindQuery($0, of: id) },
            stepFind: { detailStore.stepFind($0, in: $1, of: id) },
            endFind: { detailStore.endFind(of: id) },
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
            toggleJobArtifacts: { detailStore.toggleJobArtifacts($0, of: id) },
            downloadArtifacts: { detailStore.downloadArtifacts($0, named: $1, of: id) },
            runCISetup: { appActions.runInTerminal($0, at: detailStore.ciCheckoutPath, title: "Started the CircleCI setup in Terminal") },
            startAutoRerun: { autoRerun.start(id, maxAttempts: $0) },
            stopAutoRerun: { autoRerun.stop(id) },
            setAutoRerunOnlyFlaky: { autoRerun.setOnlyFlaky($0) },
            copyCIDiagnostics: { Task { await diagnostics.copy(detailStore.ciDiagnosticsSnapshot(of: id, reference: detailStore.words.reference(id))) } },
            saveCIDiagnostics: { Task { await diagnostics.save(detailStore.ciDiagnosticsSnapshot(of: id, reference: detailStore.words.reference(id))) } },
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
            refresh: {
                Task {
                    await pullRequests.refresh()
                    await detailStore.refresh(pullRequests.requests.first { $0.id == id } ?? summary)
                }
            },
            retry: { Task { await detailStore.reload(id) } }
        )
    }
}
