import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class MergeRequestDetailStore {
    private(set) var details: [MergeRequestSummary.ID: MergeRequestDetails] = [:]
    private(set) var diffs: [MergeRequestSummary.ID: [MergeRequestFileDiff]] = [:]
    private(set) var errors: [MergeRequestSummary.ID: String] = [:]
    private(set) var expandedFiles: [MergeRequestSummary.ID: Set<MergeRequestFileDiff.ID>] = [:]
    private(set) var viewedFiles: [MergeRequestSummary.ID: Set<MergeRequestFileDiff.ID>] = [:]
    private(set) var focus: DiffFocus?
    private(set) var busyThreads: Set<MergeRequestThread.ID> = []
    private(set) var showsThreadsInDiff = true
    private(set) var openDiffThreads: Set<MergeRequestThread.ID> = []

    @ObservationIgnored private let repository: MergeRequestRepository
    @ObservationIgnored private let remote: any GitLabRemoteLookup
    @ObservationIgnored private let prompts: any ReviewPromptRepository
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private var loading: Set<MergeRequestSummary.ID> = []
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(repository: MergeRequestRepository, remote: any GitLabRemoteLookup, prompts: any ReviewPromptRepository, activity: ActivityLog, events: AppEvents) {
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
            focus = nil
        }
    }

    func isLoaded(_ id: MergeRequestSummary.ID) -> Bool {
        details[id] != nil && diffs[id] != nil
    }

    func expandedFiles(of id: MergeRequestSummary.ID) -> Set<MergeRequestFileDiff.ID> {
        expandedFiles[id] ?? []
    }

    func review(of id: MergeRequestSummary.ID) -> MergeRequestReviewState {
        MergeRequestReviewState(
            expandedFiles: expandedFiles(of: id),
            viewedFiles: viewedFiles[id] ?? [],
            focus: focus(of: id),
            busyThreads: busyThreads,
            showsThreadsInDiff: showsThreadsInDiff,
            openDiffThreads: openDiffThreads
        )
    }

    func focus(of id: MergeRequestSummary.ID) -> DiffFocus? {
        focus?.requestID == id ? focus : nil
    }

    func toggleFile(_ fileID: MergeRequestFileDiff.ID, of id: MergeRequestSummary.ID) {
        var files = expandedFiles(of: id)
        if files.remove(fileID) == nil {
            files.insert(fileID)
        }
        expandedFiles[id] = files
        clearFocus(of: id)
    }

    func expandAllFiles(of id: MergeRequestSummary.ID) {
        let viewed = viewedFiles[id] ?? []
        expandedFiles[id] = Set((diffs[id] ?? []).map(\.id)).subtracting(viewed)
        clearFocus(of: id)
    }

    func collapseAllFiles(of id: MergeRequestSummary.ID) {
        expandedFiles[id] = []
        clearFocus(of: id)
    }

    func toggleViewed(_ fileID: MergeRequestFileDiff.ID, of id: MergeRequestSummary.ID) {
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

    func toggleDiffThread(_ threadID: MergeRequestThread.ID) {
        if openDiffThreads.remove(threadID) == nil {
            openDiffThreads.insert(threadID)
        }
    }

    func openAllDiffThreads(of id: MergeRequestSummary.ID) {
        showsThreadsInDiff = true
        openDiffThreads.formUnion((details[id]?.threads ?? []).map(\.id))
    }

    func foldAllDiffThreads(of id: MergeRequestSummary.ID) {
        openDiffThreads.subtract((details[id]?.threads ?? []).map(\.id))
    }

    private func clearFocus(of id: MergeRequestSummary.ID) {
        if focus?.requestID == id {
            focus = nil
        }
    }

    func showInDiff(threadID: MergeRequestThread.ID, of id: MergeRequestSummary.ID) {
        guard let thread = details[id]?.threads.first(where: { $0.id == threadID }),
              let path = thread.filePath,
              let line = thread.line else { return }
        expandedFiles[id, default: []].insert(path)
        openDiffThreads.insert(threadID)
        focus = DiffFocus(requestID: id, path: path, line: line, isOld: thread.isOnOldLine)
    }

    func load(_ id: MergeRequestSummary.ID) async {
        guard isLoaded(id) == false, loading.contains(id) == false else { return }
        loading.insert(id)
        defer { loading.remove(id) }
        errors[id] = nil
        do {
            let url = try await remote.gitLabURL()
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

    func writeReviewPrompt(for summary: MergeRequestSummary) async -> String? {
        await load(summary.id)
        guard let threads = details[summary.id]?.threads else {
            activity.log("Cannot read the threads of !\(summary.iid)", detail: errors[summary.id] ?? "", outcome: .failure)
            return nil
        }
        guard threads.isEmpty == false else {
            activity.log("!\(summary.iid) has no open threads", detail: "Nothing to fix", outcome: .info)
            return nil
        }
        do {
            return try await prompts.save(ReviewPromptBuilder.prompt(for: summary, threads: threads), iid: summary.iid)
        } catch {
            activity.log("Cannot write the review prompt of !\(summary.iid)", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    func resolveThread(_ threadID: MergeRequestThread.ID, of id: MergeRequestSummary.ID) {
        run(threadID, of: id, "Resolved a thread of !\(id)") { [repository] in
            try await repository.resolveThread(id: threadID, repository: $0)
        }
    }

    func reply(_ body: String, to threadID: MergeRequestThread.ID, of id: MergeRequestSummary.ID) {
        let text = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.isEmpty == false else { return }
        run(threadID, of: id, "Replied in a thread of !\(id)") { [repository] in
            try await repository.reply(threadID: threadID, body: text, iid: id, repository: $0)
        }
    }

    private func run(_ threadID: MergeRequestThread.ID, of id: MergeRequestSummary.ID, _ title: String, _ work: @escaping @Sendable (URL) async throws -> Void) {
        guard busyThreads.contains(threadID) == false else { return }
        busyThreads.insert(threadID)
        Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await remote.gitLabURL()
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

    func reload(_ id: MergeRequestSummary.ID) async {
        details[id] = nil
        diffs[id] = nil
        await load(id)
    }
}
