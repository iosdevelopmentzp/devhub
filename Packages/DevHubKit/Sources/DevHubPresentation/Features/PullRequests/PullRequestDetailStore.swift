import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class PullRequestDetailStore {
    private(set) var details: [PullRequestSummary.ID: PullRequestDetails] = [:]
    private(set) var diffs: [PullRequestSummary.ID: [PullRequestFileDiff]] = [:]
    private(set) var errors: [PullRequestSummary.ID: String] = [:]
    private(set) var expandedFiles: [PullRequestSummary.ID: Set<PullRequestFileDiff.ID>] = [:]
    private(set) var viewedFiles: [PullRequestSummary.ID: Set<PullRequestFileDiff.ID>] = [:]
    private(set) var focus: DiffFocus?
    private(set) var busyThreads: Set<ReviewThread.ID> = []
    private(set) var showsThreadsInDiff = true
    private(set) var openDiffThreads: Set<ReviewThread.ID> = []
    private(set) var shownHiddenFiles: Set<PullRequestSummary.ID> = []
    private(set) var toggledGroups: [PullRequestSummary.ID: Set<String>] = [:]
    private(set) var commentDrafts: [PullRequestSummary.ID: String] = [:]
    private(set) var busyComments: Set<PullRequestSummary.ID> = []
    private(set) var lineComment: LineCommentDraft?
    private(set) var isSendingLineComment = false
    private(set) var jobLogs: [String: JobLogState] = [:]
    private(set) var openJobLogs: Set<String> = []
    private(set) var busyJobs: Set<String> = []
    private(set) var fullFiles: [PullRequestSummary.ID: Set<PullRequestFileDiff.ID>] = [:]
    private(set) var fileContents: [PullRequestSummary.ID: [String: [String]]] = [:]
    private(set) var ciToolState: CIToolState?
    private(set) var ciWorkflows: [String: CIWorkflow] = [:]
    private(set) var ciWorkflowErrors: [String: String] = [:]
    private(set) var ciFailedTests: [String: [CITestResult]] = [:]
    private(set) var ciFlakyTests: [CIFlakyTest] = []
    private(set) var ciBusyWorkflows: Set<String> = []
    private(set) var ciWorkflowDetails: [String: CIWorkflowDetails] = [:]
    private(set) var ciJobSteps: [String: [CIJobStep]] = [:]
    private(set) var ciArtifacts: [String: CIArtifactsState] = [:]
    private(set) var openJobArtifacts: Set<String> = []
    private(set) var ciDownloads: [String: CIDownloadState] = [:]
    private(set) var shownCIHistory: Set<PullRequestSummary.ID> = []
    private(set) var openJobDetails: Set<String> = []
    private(set) var openTestMessages: Set<String> = []
    private(set) var openCIHistoryRuns: Set<String> = []
    private(set) var onlyChangedSinceReview: Set<PullRequestSummary.ID> = []

    enum CommentKind {
        case comment
        case requestChanges
    }

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let ci: any CIRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    @ObservationIgnored private let projects: CIProjectResolver
    @ObservationIgnored private let history: CIWorkflowHistory
    @ObservationIgnored private let autoRerun: any CIAutoRerunLookup
    @ObservationIgnored private let hiddenFiles: PullRequestHiddenFiles
    @ObservationIgnored private let reviews: PullRequestReviewMemory
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let operations: OperationLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let ciPollInterval: Duration
    @ObservationIgnored private var ciPolls: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var ciPollErrors: [String: String] = [:]
    @ObservationIgnored private var loading: Set<PullRequestSummary.ID> = []
    @ObservationIgnored private var fingerprints: [PullRequestSummary.ID: [String: String]] = [:]
    @ObservationIgnored private var ciLoading: Set<String> = []
    @ObservationIgnored private var ciFlakyLoaded = false
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let failedTestJobLimit = 5

    var words: CodeHostWords {
        remote.words
    }

    init(
        repository: CodeHostRepository,
        ci: any CIRepository,
        remote: any CodeHostLookup,
        prompts: any ReviewPromptRepository,
        projects: CIProjectResolver,
        history: CIWorkflowHistory,
        autoRerun: any CIAutoRerunLookup,
        hiddenFiles: PullRequestHiddenFiles,
        reviews: PullRequestReviewMemory,
        activity: ActivityLog,
        operations: OperationLog,
        ciPollInterval: Duration,
        events: AppEvents
    ) {
        self.repository = repository
        self.ci = ci
        self.remote = remote
        self.prompts = prompts
        self.projects = projects
        self.history = history
        self.autoRerun = autoRerun
        self.hiddenFiles = hiddenFiles
        self.reviews = reviews
        self.activity = activity
        self.operations = operations
        self.events = events
        self.ciPollInterval = ciPollInterval
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                resetProject()
            case .pullRequestChecksChanged(let iid):
                guard details[iid] != nil else { return }
                Task { await self.reload(iid) }
            case .pullRequestReviewed(let iid):
                recordReview(of: iid)
            default:
                break
            }
        }
    }

    private func resetProject() {
        resetCI()
        shownCIHistory = []
        openJobDetails = []
        openTestMessages = []
        openCIHistoryRuns = []
        details = [:]
        diffs = [:]
        errors = [:]
        expandedFiles = [:]
        viewedFiles = [:]
        onlyChangedSinceReview = []
        fingerprints = [:]
        openDiffThreads = []
        shownHiddenFiles = []
        toggledGroups = [:]
        commentDrafts = [:]
        lineComment = nil
        jobLogs = [:]
        openJobLogs = []
        fullFiles = [:]
        fileContents = [:]
        focus = nil
    }

    func isLoaded(_ id: PullRequestSummary.ID) -> Bool {
        details[id] != nil && diffs[id] != nil
    }

    func expandedFiles(of id: PullRequestSummary.ID) -> Set<PullRequestFileDiff.ID> {
        expandedFiles[id] ?? []
    }

    func review(of id: PullRequestSummary.ID) -> PullRequestReviewState {
        PullRequestReviewState(
            expandedFiles: expandedFiles(of: id),
            viewedFiles: viewedFiles[id] ?? [],
            focus: focus(of: id),
            busyThreads: busyThreads,
            showsThreadsInDiff: showsThreadsInDiff,
            openDiffThreads: openDiffThreads,
            showsHiddenFiles: shownHiddenFiles.contains(id),
            commentDraft: commentDrafts[id] ?? "",
            isCommentBusy: busyComments.contains(id),
            lineComment: lineComment?.requestID == id ? lineComment : nil,
            isLineCommentBusy: lineComment?.requestID == id && isSendingLineComment,
            jobLogs: jobLogs,
            openJobLogs: openJobLogs,
            busyJobs: busyJobs,
            fullFiles: fullFiles[id] ?? [],
            fileContents: fileContents[id] ?? [:],
            hasCIProvider: hasCIProvider(for: id),
            ciToolState: ciToolState,
            ciWorkflows: ciWorkflows,
            ciWorkflowErrors: ciWorkflowErrors,
            ciFailedTests: ciFailedTests,
            ciFlakyTests: FlakyTrackingPolicy.merged(insights: ciFlakyTests, ledger: history.flakyTests),
            ciBusyWorkflows: ciBusyWorkflows,
            ciWorkflowDetails: ciWorkflowDetails,
            ciJobSteps: ciJobSteps,
            ciArtifacts: ciArtifacts,
            openJobArtifacts: openJobArtifacts,
            ciDownloads: ciDownloads,
            ciHistory: CIHistoryPolicy.previous(in: history.records(for: id), current: Set(details[id]?.jobs.compactMap(\.ciWorkflowID) ?? [])),
            showsCIHistory: shownCIHistory.contains(id),
            autoRerunPlan: autoRerun.plan(for: id),
            autoRerunOnlyFlaky: autoRerun.onlyFlaky,
            openJobDetails: openJobDetails,
            openTestMessages: openTestMessages,
            openCIHistoryRuns: openCIHistoryRuns,
            chosenHiddenFiles: hiddenFiles.paths,
            toggledGroups: toggledGroups[id] ?? [],
            reviewedAt: reviews.snapshot(of: id)?.reviewedAt,
            changedSinceReview: hostReviewCommits(of: id) == nil ? ReviewChangePolicy.changedPaths(since: reviews.snapshot(of: id), paths: diffs[id]?.map(\.path) ?? [], fingerprints: fingerprints[id] ?? [:]) : [],
            hostReview: hostReviewCommits(of: id) == nil ? nil : details[id]?.myLastReview,
            commitsSinceHostReview: hostReviewCommits(of: id),
            showsOnlyChangedSinceReview: onlyChangedSinceReview.contains(id)
        )
    }

    private func hostReviewCommits(of id: PullRequestSummary.ID) -> Int? {
        guard reviews.isOn, let details = details[id], let review = details.myLastReview, ReviewChangePolicy.isNewer(review, than: reviews.snapshot(of: id)) else { return nil }
        let count = ReviewChangePolicy.commitsSince(review, commitDates: details.commitDates)
        return count > 0 ? count : nil
    }

    func toggleOnlyChangedSinceReview(of id: PullRequestSummary.ID) {
        if onlyChangedSinceReview.remove(id) == nil {
            onlyChangedSinceReview.insert(id)
        }
    }

    func forgetReview(of id: PullRequestSummary.ID) {
        onlyChangedSinceReview.remove(id)
        reviews.forget(id)
    }

    private func recordReview(of id: PullRequestSummary.ID) {
        guard let fingerprints = fingerprints[id] else { return }
        reviews.recordReview(of: id, fingerprints: fingerprints)
    }

    func focus(of id: PullRequestSummary.ID) -> DiffFocus? {
        focus?.requestID == id ? focus : nil
    }

    func toggleFile(_ fileID: PullRequestFileDiff.ID, of id: PullRequestSummary.ID) {
        var files = expandedFiles(of: id)
        if files.remove(fileID) == nil {
            files.insert(fileID)
        }
        expandedFiles[id] = files
        clearFocus(of: id)
    }

    func expandAllFiles(_ fileIDs: Set<PullRequestFileDiff.ID>, of id: PullRequestSummary.ID) {
        let viewed = viewedFiles[id] ?? []
        expandedFiles[id] = expandedFiles(of: id).union(fileIDs).subtracting(viewed)
        clearFocus(of: id)
    }

    func collapseAllFiles(of id: PullRequestSummary.ID) {
        expandedFiles[id] = []
        clearFocus(of: id)
    }

    func hideFiles(_ paths: [String]) {
        hiddenFiles.hide(paths)
    }

    func unhideFile(_ path: String) {
        hiddenFiles.unhide(path)
    }

    func toggleHiddenFiles(of id: PullRequestSummary.ID) {
        if shownHiddenFiles.remove(id) == nil {
            shownHiddenFiles.insert(id)
        }
    }

    func revealFile(_ fileID: PullRequestFileDiff.ID, of id: PullRequestSummary.ID) {
        expandedFiles[id, default: []].insert(fileID)
        focus = DiffFocus(requestID: id, path: fileID, line: 0, isOld: false)
    }

    func toggleFileGroup(_ name: String, of id: PullRequestSummary.ID) {
        var toggled = toggledGroups[id] ?? []
        if toggled.remove(name) == nil {
            toggled.insert(name)
        }
        toggledGroups[id] = toggled
    }

    func toggleViewed(_ fileID: PullRequestFileDiff.ID, of id: PullRequestSummary.ID) {
        var viewed = viewedFiles[id] ?? []
        let isViewed = viewed.remove(fileID) == nil
        if isViewed {
            viewed.insert(fileID)
            expandedFiles[id]?.remove(fileID)
        }
        viewedFiles[id] = viewed
        reviews.setViewed(isViewed, path: fileID, fingerprint: fingerprints[id]?[fileID], of: id)
        if isViewed, ReviewChangePolicy.isEveryFileViewed(viewed, paths: diffs[id]?.map(\.path) ?? []) {
            recordReview(of: id)
        }
    }

    func toggleThreadsInDiff() {
        showsThreadsInDiff.toggle()
    }

    func toggleDiffThread(_ threadID: ReviewThread.ID) {
        if openDiffThreads.remove(threadID) == nil {
            openDiffThreads.insert(threadID)
        }
    }

    func openAllDiffThreads(of id: PullRequestSummary.ID) {
        showsThreadsInDiff = true
        openDiffThreads.formUnion((details[id]?.threads ?? []).map(\.id))
    }

    func foldAllDiffThreads(of id: PullRequestSummary.ID) {
        openDiffThreads.subtract((details[id]?.threads ?? []).map(\.id))
    }

    func fileWebURL(path: String, line: Int?, of summary: PullRequestSummary) -> URL? {
        guard let host = remote.current else { return nil }
        return RepositoryWebLinks.fileURL(base: host.webURL, kind: host.kind, ref: summary.headSHA ?? summary.sourceBranch, path: path, line: line)
    }

    func toggleFullFile(_ fileID: PullRequestFileDiff.ID, of summary: PullRequestSummary) {
        let id = summary.id
        var files = fullFiles[id] ?? []
        if files.remove(fileID) == nil {
            files.insert(fileID)
        }
        fullFiles[id] = files
        guard files.contains(fileID), fileContents[id]?[fileID] == nil else { return }
        let ref = summary.headSHA ?? summary.sourceBranch
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                let text = try await repository.fileContent(path: fileID, ref: ref, repository: url)
                fileContents[id, default: [:]][fileID] = Self.lines(of: text)
            } catch {
                activity.log("Cannot read \(fileID) at \(ref)", detail: error.localizedDescription, outcome: .failure)
                fullFiles[id]?.remove(fileID)
            }
        }
    }

    private static func lines(of text: String) -> [String] {
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" {
            lines.removeLast()
        }
        return lines
    }

    private func clearFocus(of id: PullRequestSummary.ID) {
        if focus?.requestID == id {
            focus = nil
        }
    }

    func showInDiff(threadID: ReviewThread.ID, of id: PullRequestSummary.ID) {
        guard let thread = details[id]?.threads.first(where: { $0.id == threadID }),
              let path = thread.filePath,
              let line = thread.line else { return }
        expandedFiles[id, default: []].insert(path)
        openDiffThreads.insert(threadID)
        focus = DiffFocus(requestID: id, path: path, line: line, isOld: thread.isOnOldLine)
    }

    func load(_ id: PullRequestSummary.ID) async {
        guard isLoaded(id) == false, loading.contains(id) == false else { return }
        loading.insert(id)
        defer { loading.remove(id) }
        errors[id] = nil
        do {
            let url = try await remote.codeHost()
            async let loadedDetails = repository.details(iid: id, repository: url)
            async let loadedDiffs = repository.diffs(iid: id, repository: url)
            let (description, files) = try await (loadedDetails, loadedDiffs)
            details[id] = description
            diffs[id] = files
            restoreViewed(of: id, files: files)
            adoptHostReview(of: id, details: description)
            history.load(id)
            loadCI(of: id)
        } catch is CancellationError {
        } catch {
            errors[id] = error.localizedDescription
        }
    }

    private func adoptHostReview(of id: PullRequestSummary.ID, details: PullRequestDetails) {
        guard let review = details.myLastReview, ReviewChangePolicy.isNewer(review, than: reviews.snapshot(of: id)) else { return }
        guard ReviewChangePolicy.commitsSince(review, commitDates: details.commitDates) == 0 else { return }
        reviews.recordHostReview(review, of: id, fingerprints: fingerprints[id] ?? [:])
    }

    private func restoreViewed(of id: PullRequestSummary.ID, files: [PullRequestFileDiff]) {
        let current = ReviewChangePolicy.fingerprints(of: files)
        fingerprints[id] = current
        guard reviews.isOn else {
            viewedFiles[id] = viewedFiles[id]?.intersection(current.keys)
            return
        }
        viewedFiles[id] = ReviewChangePolicy.viewedPaths(in: reviews.snapshot(of: id), fingerprints: current)
    }

    func writeReviewPrompt(for summary: PullRequestSummary) async -> String? {
        await load(summary.id)
        guard let threads = details[summary.id]?.threads else {
            activity.log("Cannot read the threads of \(remote.words.reference(summary.iid))", detail: errors[summary.id] ?? "", outcome: .failure)
            return nil
        }
        guard threads.isEmpty == false else {
            activity.log("\(remote.words.reference(summary.iid)) has no open threads", detail: "Nothing to fix", outcome: .info)
            return nil
        }
        do {
            return try await prompts.save(ReviewPromptBuilder.prompt(for: summary, threads: threads), iid: summary.iid)
        } catch {
            activity.log("Cannot write the review prompt of \(remote.words.reference(summary.iid))", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    func resolveThread(_ threadID: ReviewThread.ID, of id: PullRequestSummary.ID) {
        run(threadID, of: id, action: "Resolve a thread of \(remote.words.reference(id))", "Resolved a thread of \(remote.words.reference(id))") { [repository] in
            try await repository.resolveThread(id: threadID, repository: $0)
        }
    }

    func reply(_ body: String, to threadID: ReviewThread.ID, of id: PullRequestSummary.ID) {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        run(threadID, of: id, action: "Reply in a thread of \(remote.words.reference(id))", "Replied in a thread of \(remote.words.reference(id))") { [repository] in
            try await repository.reply(threadID: threadID, body: text, iid: id, repository: $0)
        }
    }

    func setCommentDraft(_ text: String, of id: PullRequestSummary.ID) {
        commentDrafts[id] = text.isEmpty ? nil : text
    }

    func send(_ kind: CommentKind, on id: PullRequestSummary.ID) {
        let text = (commentDrafts[id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false, busyComments.contains(id) == false else { return }
        busyComments.insert(id)
        let reference = remote.words.reference(id)
        let title = kind == .comment ? "Commented on \(reference)" : "Requested changes on \(reference)"
        let action = kind == .comment ? "Comment on \(reference)" : "Request changes on \(reference)"
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(action, at: .pullRequest(id), retry: nil) {
                    let url = try await remote.codeHost()
                    switch kind {
                    case .comment: try await repository.comment(iid: id, body: text, repository: url)
                    case .requestChanges: try await repository.requestChanges(iid: id, body: text, repository: url)
                    }
                }
                activity.log(title, detail: text, outcome: .success)
                commentDrafts[id] = nil
                busyComments.remove(id)
                recordReview(of: id)
                await reload(id)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
                busyComments.remove(id)
            }
        }
    }

    func startLineComment(path: String, oldPath: String, lineID: Int, newLine: Int?, oldLine: Int?, of id: PullRequestSummary.ID) {
        guard isSendingLineComment == false, newLine != nil || oldLine != nil else { return }
        lineComment = LineCommentDraft(requestID: id, path: path, oldPath: oldPath, lineID: lineID, newLine: newLine, oldLine: oldLine, text: "")
    }

    func setLineCommentText(_ text: String) {
        lineComment?.text = text
    }

    func cancelLineComment() {
        guard isSendingLineComment == false else { return }
        lineComment = nil
    }

    func sendLineComment(headSHA: String?) {
        guard let draft = lineComment, isSendingLineComment == false else { return }
        let text = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        isSendingLineComment = true
        let comment = PullRequestLineComment(path: draft.path, oldPath: draft.oldPath, newLine: draft.newLine, oldLine: draft.oldLine, body: text, headSHA: headSHA)
        let place = "\(draft.path):\(draft.newLine ?? draft.oldLine ?? 0) in \(remote.words.reference(draft.requestID))"
        let title = "Commented on \(place)"
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform("Comment on \(place)", at: .pullRequest(draft.requestID), retry: nil) {
                    let url = try await remote.codeHost()
                    try await repository.addLineComment(iid: draft.requestID, comment: comment, repository: url)
                }
                activity.log(title, detail: text, outcome: .success)
                lineComment = nil
                isSendingLineComment = false
                await reload(draft.requestID)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
                isSendingLineComment = false
            }
        }
    }

    func toggleJobDetails(_ key: String) {
        toggle(key, in: \.openJobDetails)
    }

    func toggleTestMessage(_ key: String) {
        toggle(key, in: \.openTestMessages)
    }

    func toggleCIHistoryRun(_ workflowID: String) {
        toggle(workflowID, in: \.openCIHistoryRuns)
    }

    private func toggle(_ key: String, in set: ReferenceWritableKeyPath<PullRequestDetailStore, Set<String>>) {
        if self[keyPath: set].remove(key) == nil {
            self[keyPath: set].insert(key)
        }
    }

    func toggleJobLog(_ jobID: String) {
        guard openJobLogs.remove(jobID) == nil else { return }
        openJobLogs.insert(jobID)
        if case .loaded = jobLogs[jobID] { return }
        jobLogs[jobID] = .loading
        let ciProject = ciWorkflow(containing: jobID) == nil ? nil : projects.project(for: [])
        Task { [weak self] in
            guard let self else { return }
            do {
                if let ciProject {
                    jobLogs[jobID] = .loaded(try await ci.jobLog(jobID: jobID, project: ciProject))
                } else {
                    let url = try await remote.codeHost()
                    jobLogs[jobID] = .loaded(try await repository.jobLog(jobID: jobID, repository: url))
                }
            } catch {
                jobLogs[jobID] = .failure(error.localizedDescription)
            }
        }
    }

    func retryJob(_ jobID: String, named name: String, of id: PullRequestSummary.ID) {
        if let workflow = ciWorkflow(containing: jobID) {
            rerunWorkflow(workflow.id, fromFailed: true, of: id)
            return
        }
        guard busyJobs.contains(jobID) == false else { return }
        busyJobs.insert(jobID)
        let title = "Retried \(name) of \(remote.words.reference(id))"
        let retry: () -> Void = { [weak self] in
            guard let self else { return }
            retryJob(jobID, named: name, of: id)
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform("Retry \(name) of \(remote.words.reference(id))", at: .pullRequest(id), retry: retry) {
                    let url = try await remote.codeHost()
                    try await repository.retryJob(jobID: jobID, repository: url)
                }
                activity.log(title, detail: "", outcome: .success)
                busyJobs.remove(jobID)
                jobLogs[jobID] = nil
                openJobLogs.remove(jobID)
                await reload(id)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
                busyJobs.remove(jobID)
            }
        }
    }

    private func run(_ threadID: ReviewThread.ID, of id: PullRequestSummary.ID, action: String, _ title: String, _ work: @escaping @Sendable (CodeHost) async throws -> Void) {
        guard busyThreads.contains(threadID) == false else { return }
        busyThreads.insert(threadID)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(action, at: .pullRequest(id), retry: nil) {
                    let url = try await remote.codeHost()
                    try await work(url)
                }
                activity.log(title, detail: "", outcome: .success)
                busyThreads.remove(threadID)
                await reload(id)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
                busyThreads.remove(threadID)
            }
        }
    }

    func reload(_ id: PullRequestSummary.ID) async {
        clearCI(of: id)
        details[id] = nil
        diffs[id] = nil
        fileContents[id] = nil
        await load(id)
    }

    // MARK: - CI

    var ciCheckoutPath: String {
        projects.checkoutPath
    }

    func ciDiagnosticsSnapshot(of id: PullRequestSummary.ID, reference: String) -> CIDiagnosticsSnapshot {
        CIDiagnosticsSnapshot(
            requestReference: reference,
            requestWorkflows: (details[id]?.jobs.compactMap(\.ciWorkflowID) ?? []).compactMap { ciWorkflows[$0] },
            requestWorkflowErrors: ciWorkflowErrors
        )
    }

    var ciProvider: CIProvider? {
        projects.provider
    }

    func toggleCIHistory(of id: PullRequestSummary.ID) {
        if shownCIHistory.contains(id) {
            shownCIHistory.remove(id)
        } else {
            shownCIHistory.insert(id)
        }
    }

    func clearCIHistory(of id: PullRequestSummary.ID) {
        history.clear(id)
        shownCIHistory.remove(id)
    }

    func ciWorkflow(containing jobID: String) -> CIWorkflow? {
        ciWorkflows.values.first { workflow in workflow.jobs.contains { $0.id == jobID } }
    }

    func rerunWorkflow(_ workflowID: String, fromFailed: Bool, of id: PullRequestSummary.ID) {
        let name = ciWorkflows[workflowID]?.name ?? "the workflow"
        let title = fromFailed ? "Re-ran the failed jobs of \(name)" : "Re-ran \(name)"
        let action = fromFailed ? "Re-run the failed jobs of \(name)" : "Re-run \(name)"
        runCI(workflowID: workflowID, of: id, action: action, title) { [ci] in
            try await ci.rerun(workflowID: workflowID, fromFailed: fromFailed, project: $0)
        }
    }

    func cancelWorkflow(_ workflowID: String, of id: PullRequestSummary.ID) {
        let name = ciWorkflows[workflowID]?.name ?? "the workflow"
        runCI(workflowID: workflowID, of: id, action: "Cancel \(name)", "Cancelled \(name)") { [ci] in
            try await ci.cancel(workflowID: workflowID, project: $0)
        }
    }

    func approveJob(_ jobID: String, named name: String, of id: PullRequestSummary.ID) {
        guard let workflow = ciWorkflow(containing: jobID), let runID = workflow.runID else { return }
        runCI(workflowID: workflow.id, of: id, action: "Approve \(name) of \(workflow.name)", "Approved \(name) of \(workflow.name)") { [ci] in
            try await ci.approve(runID: runID, job: name, project: $0)
        }
    }

    private func runCI(workflowID: String, of id: PullRequestSummary.ID, action: String, _ title: String, _ work: @escaping @Sendable (CIProject) async throws -> Void) {
        guard ciBusyWorkflows.contains(workflowID) == false else { return }
        ciBusyWorkflows.insert(workflowID)
        let project = projects.project(for: details[id]?.jobs ?? [])
        Task { [weak self] in
            guard let self else { return }
            do {
                try await operations.perform(action, at: .pullRequest(id), retry: nil) {
                    try await work(project)
                }
                activity.log(title, detail: "", outcome: .success)
                ciBusyWorkflows.remove(workflowID)
                await reload(id)
                events.post(.pullRequestsChanged)
            } catch {
                activity.log("\(title) failed", detail: error.localizedDescription, outcome: .failure)
                ciBusyWorkflows.remove(workflowID)
            }
        }
    }

    private func hasCIProvider(for id: PullRequestSummary.ID) -> Bool {
        projects.hasProvider(for: details[id]?.jobs ?? [])
    }

    private func loadCI(of id: PullRequestSummary.ID) {
        guard let jobs = details[id]?.jobs else { return }
        var missing: [String] = []
        for workflowID in jobs.compactMap(\.ciWorkflowID) where ciWorkflows[workflowID] == nil && ciLoading.contains(workflowID) == false && missing.contains(workflowID) == false {
            missing.append(workflowID)
        }
        guard missing.isEmpty == false, ciProvider != nil else { return }
        let project = projects.project(for: jobs)
        let workflowIDs = missing
        ciLoading.formUnion(workflowIDs)
        Task { [weak self] in
            guard let self else { return }
            defer { ciLoading.subtract(workflowIDs) }
            guard await checkCITool(project: project) else { return }
            for workflowID in workflowIDs {
                await loadCIWorkflow(workflowID, project: project, of: id)
            }
        }
    }

    private func checkCITool(project: CIProject) async -> Bool {
        if let ciToolState {
            return CIPolicy.installCommand(for: ciToolState) == nil
        }
        do {
            let state = try await ci.toolState(project: project)
            ciToolState = state
            return CIPolicy.installCommand(for: state) == nil
        } catch {
            activity.log("Cannot check the circleci tool", detail: error.localizedDescription, outcome: .failure)
            return false
        }
    }

    private func loadCIWorkflow(_ workflowID: String, project: CIProject, of id: PullRequestSummary.ID) async {
        do {
            let workflow = try await ci.workflow(id: workflowID, project: project)
            ciWorkflows[workflowID] = workflow
            ciWorkflowErrors[workflowID] = nil
            await loadCIWorkflowDetails(workflowID, project: project)
            await loadCIFailedTests(of: workflow, project: project)
            await loadCIJobSteps(of: workflow, project: project)
            history.remember(workflow, failedTests: ciFailedTests, for: id)
            pollCIWorkflow(workflow, project: project, of: id)
        } catch {
            ciWorkflowErrors[workflowID] = error.localizedDescription
            activity.log("Cannot read the CircleCI workflow", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func loadCIWorkflowDetails(_ workflowID: String, project: CIProject) async {
        do {
            ciWorkflowDetails[workflowID] = try await ci.workflowDetails(id: workflowID, project: project)
        } catch {
            activity.log("Cannot read the job details of the CircleCI workflow", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func loadCIJobSteps(of workflow: CIWorkflow, project: CIProject) async {
        for job in workflow.jobs.filter({ $0.status == .failed && ciJobSteps[$0.id] == nil }).prefix(Self.failedTestJobLimit) {
            do {
                ciJobSteps[job.id] = try await ci.jobSteps(jobID: job.id, project: project)
            } catch {
                ciJobSteps[job.id] = []
                activity.log("Cannot read the steps of \(job.name)", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    static func pollsWorkflow(_ status: CheckStatus) -> Bool {
        PipelineStatePolicy.isActive(status) || status == .manual
    }

    private func pollCIWorkflow(_ workflow: CIWorkflow, project: CIProject, of id: PullRequestSummary.ID) {
        guard Self.pollsWorkflow(workflow.status), ciPolls[workflow.id] == nil else { return }
        ciPolls[workflow.id] = Task { [weak self] in
            var interval = self?.ciPollInterval ?? .seconds(30)
            while Task.isCancelled == false {
                try? await Task.sleep(for: interval)
                guard Task.isCancelled == false, let self else { return }
                do {
                    let latest = try await ci.workflow(id: workflow.id, project: project)
                    ciPollErrors[workflow.id] = nil
                    interval = ciPollInterval
                    if latest != ciWorkflows[workflow.id] {
                        ciWorkflows[workflow.id] = latest
                    }
                    if ciWorkflowDetails[workflow.id] != nil {
                        await loadCIWorkflowDetails(workflow.id, project: project)
                    }
                    guard Self.pollsWorkflow(latest.status) == false else { continue }
                    await loadCIFailedTests(of: latest, project: project)
                    await loadCIJobSteps(of: latest, project: project)
                    history.remember(latest, failedTests: ciFailedTests, for: id)
                    ciPolls[workflow.id] = nil
                    activity.log("CircleCI: \(latest.name.isEmpty ? "the workflow" : latest.name) \(Self.endWord(latest.status))", detail: "", outcome: latest.status == .failed ? .failure : .success)
                    events.post(.pullRequestChecksChanged(iid: id))
                    return
                } catch CIError.rateLimited {
                    interval = ciPollInterval * 2
                    reportPollError(CIError.rateLimited.localizedDescription, of: workflow.id)
                } catch is CancellationError {
                    return
                } catch {
                    reportPollError(error.localizedDescription, of: workflow.id)
                }
            }
        }
    }

    private func reportPollError(_ message: String, of workflowID: String) {
        guard ciPollErrors[workflowID] != message else { return }
        ciPollErrors[workflowID] = message
        activity.log("Cannot read the CircleCI workflow again", detail: message, outcome: .failure)
    }

    private static func endWord(_ status: CheckStatus) -> String {
        switch status {
        case .success: "passed"
        case .failed: "failed"
        case .canceled: "was cancelled"
        default: status.name
        }
    }

    func toggleJobArtifacts(_ jobID: String, of id: PullRequestSummary.ID) {
        guard openJobArtifacts.remove(jobID) == nil else { return }
        openJobArtifacts.insert(jobID)
        if case .loaded = ciArtifacts[jobID] { return }
        ciArtifacts[jobID] = .loading
        let project = projects.project(for: details[id]?.jobs ?? [])
        Task { [weak self] in
            guard let self else { return }
            do {
                ciArtifacts[jobID] = .loaded(try await ci.artifacts(jobID: jobID, project: project))
            } catch {
                ciArtifacts[jobID] = .failure(error.localizedDescription)
                activity.log("Cannot read the artifacts of the job", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    func downloadArtifacts(_ jobID: String, named name: String, of id: PullRequestSummary.ID) {
        guard ciDownloads[jobID] != .downloading else { return }
        ciDownloads[jobID] = .downloading
        let number = ciWorkflowDetails.values.lazy.compactMap { $0.job(jobID)?.number }.first
        let folderName = number.map { "\(name) \($0)" } ?? name
        let project = projects.project(for: details[id]?.jobs ?? [])
        Task { [weak self] in
            guard let self else { return }
            do {
                let folder = try await operations.perform("Download the artifacts of \(name)", at: .pullRequest(id), retry: nil) { [ci] in
                    try await ci.downloadArtifacts(jobID: jobID, folderName: folderName, project: project)
                }
                ciDownloads[jobID] = .done(folder: folder)
                activity.log("Downloaded the artifacts of \(name)", detail: folder, outcome: .success)
            } catch {
                ciDownloads[jobID] = .failure(error.localizedDescription)
                activity.log("Cannot download the artifacts of \(name)", detail: error.localizedDescription, outcome: .failure)
            }
        }
    }

    private func loadCIFailedTests(of workflow: CIWorkflow, project: CIProject) async {
        let failedJobs = workflow.jobs.filter { $0.status == .failed && ciFailedTests[$0.id] == nil }.prefix(Self.failedTestJobLimit)
        for job in failedJobs {
            do {
                ciFailedTests[job.id] = try await ci.failedTests(jobID: job.id, project: project)
            } catch {
                ciFailedTests[job.id] = []
                activity.log("Cannot read the failed tests of \(job.name)", detail: error.localizedDescription, outcome: .failure)
            }
        }
        let hasFailedTests = failedJobs.contains { (ciFailedTests[$0.id] ?? []).isEmpty == false }
        guard hasFailedTests, ciFlakyLoaded == false else { return }
        ciFlakyLoaded = true
        do {
            ciFlakyTests = try await ci.flakyTests(project: project)
        } catch {
            ciFlakyLoaded = false
            activity.log("Cannot read the flaky tests of the project", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func clearCI(of id: PullRequestSummary.ID) {
        for workflowID in details[id]?.jobs.compactMap(\.ciWorkflowID) ?? [] {
            for job in ciWorkflows[workflowID]?.jobs ?? [] {
                ciFailedTests[job.id] = nil
                ciJobSteps[job.id] = nil
                ciArtifacts[job.id] = nil
                ciDownloads[job.id] = nil
                openJobArtifacts.remove(job.id)
                jobLogs[job.id] = nil
                openJobLogs.remove(job.id)
            }
            ciPolls[workflowID]?.cancel()
            ciPolls[workflowID] = nil
            ciPollErrors[workflowID] = nil
            ciWorkflows[workflowID] = nil
            ciWorkflowDetails[workflowID] = nil
            ciWorkflowErrors[workflowID] = nil
        }
    }

    private func resetCI() {
        for poll in ciPolls.values {
            poll.cancel()
        }
        ciPolls = [:]
        ciPollErrors = [:]
        ciWorkflowDetails = [:]
        ciJobSteps = [:]
        ciArtifacts = [:]
        openJobArtifacts = []
        ciDownloads = [:]
        ciToolState = nil
        ciWorkflows = [:]
        ciWorkflowErrors = [:]
        ciFailedTests = [:]
        ciFlakyTests = []
        ciBusyWorkflows = []
        ciFlakyLoaded = false
    }
}
