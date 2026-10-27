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
    private(set) var commentDrafts: [PullRequestSummary.ID: String] = [:]
    private(set) var busyComments: Set<PullRequestSummary.ID> = []
    private(set) var lineComment: LineCommentDraft?
    private(set) var isSendingLineComment = false

    enum CommentKind {
        case comment
        case requestChanges
    }

    @ObservationIgnored private let repository: CodeHostRepository
    @ObservationIgnored private let remote: any CodeHostLookup
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var loading: Set<PullRequestSummary.ID> = []
    @ObservationIgnored private var subscription: SubscriptionToken?

    var words: CodeHostWords {
        remote.words
    }

    init(repository: CodeHostRepository, remote: any CodeHostLookup, prompts: any ReviewPromptRepository, activity: ActivityLog, events: AppEvents) {
        self.repository = repository
        self.remote = remote
        self.prompts = prompts
        self.activity = activity
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            details = [:]
            diffs = [:]
            errors = [:]
            expandedFiles = [:]
            viewedFiles = [:]
            openDiffThreads = []
            commentDrafts = [:]
            lineComment = nil
            focus = nil
        }
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
            commentDraft: commentDrafts[id] ?? "",
            isCommentBusy: busyComments.contains(id),
            lineComment: lineComment?.requestID == id ? lineComment : nil,
            isLineCommentBusy: lineComment?.requestID == id && isSendingLineComment
        )
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

    func expandAllFiles(of id: PullRequestSummary.ID) {
        let viewed = viewedFiles[id] ?? []
        expandedFiles[id] = Set((diffs[id] ?? []).map(\.id)).subtracting(viewed)
        clearFocus(of: id)
    }

    func collapseAllFiles(of id: PullRequestSummary.ID) {
        expandedFiles[id] = []
        clearFocus(of: id)
    }

    func toggleViewed(_ fileID: PullRequestFileDiff.ID, of id: PullRequestSummary.ID) {
        var viewed = viewedFiles[id] ?? []
        if viewed.remove(fileID) == nil {
            viewed.insert(fileID)
            expandedFiles[id]?.remove(fileID)
        }
        viewedFiles[id] = viewed
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
        } catch is CancellationError {
        } catch {
            errors[id] = error.localizedDescription
        }
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
        run(threadID, of: id, "Resolved a thread of \(remote.words.reference(id))") { [repository] in
            try await repository.resolveThread(id: threadID, repository: $0)
        }
    }

    func reply(_ body: String, to threadID: ReviewThread.ID, of id: PullRequestSummary.ID) {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        run(threadID, of: id, "Replied in a thread of \(remote.words.reference(id))") { [repository] in
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
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                switch kind {
                case .comment: try await repository.comment(iid: id, body: text, repository: url)
                case .requestChanges: try await repository.requestChanges(iid: id, body: text, repository: url)
                }
                activity.log(title, detail: text, outcome: .success)
                commentDrafts[id] = nil
                busyComments.remove(id)
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
        let title = "Commented on \(draft.path):\(draft.newLine ?? draft.oldLine ?? 0) in \(remote.words.reference(draft.requestID))"
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                try await repository.addLineComment(iid: draft.requestID, comment: comment, repository: url)
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

    private func run(_ threadID: ReviewThread.ID, of id: PullRequestSummary.ID, _ title: String, _ work: @escaping @Sendable (CodeHost) async throws -> Void) {
        guard busyThreads.contains(threadID) == false else { return }
        busyThreads.insert(threadID)
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.codeHost()
                try await work(url)
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
        details[id] = nil
        diffs[id] = nil
        await load(id)
    }
}
