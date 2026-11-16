import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class GitHiddenFilesStore {
    private(set) var files: [GitHiddenFile] = []
    private(set) var diffs: [GitHiddenFile.ID: GitDiff] = [:]
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var loadedPath: String?
    var expandedIDs: Set<GitHiddenFile.ID> = []

    @ObservationIgnored private let repository: any GitChangesRepository
    @ObservationIgnored private let git: any GitRepository
    @ObservationIgnored private let trackHiddenFile: TrackHiddenFileUseCase
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let runner: ActionRunner
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        repository: any GitChangesRepository,
        git: any GitRepository,
        trackHiddenFile: TrackHiddenFileUseCase,
        checkout: any CheckoutContext,
        activity: ActivityLog,
        operations: OperationLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.git = git
        self.trackHiddenFile = trackHiddenFile
        self.checkout = checkout
        self.activity = activity
        self.events = events
        runner = ActionRunner(activity: activity, operations: operations, origin: .changes)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .branchesChanged:
                guard loadedPath != nil, busyTitle == nil else { return }
                Task { await self.refresh() }
            case .projectChanged:
                files = []
                diffs = [:]
                expandedIDs = []
                loadedPath = nil
            case .worktreesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .pullRequestChecksChanged, .pullRequestReviewed, .configChanged, .appStateReported, .refreshRequested:
                break
            }
        }
    }

    var busyTitle: String? {
        runner.busyTitle
    }

    var changedCount: Int {
        files.filter(\.hasChanges).count
    }

    func refresh() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            isLoading = true
            defer {
                if Task.isCancelled == false {
                    isLoading = false
                }
            }
            let path = checkout.checkoutPath
            do {
                let loaded = try await repository.hiddenFiles(in: path)
                try Task.checkCancellation()
                if loadedPath != path {
                    expandedIDs = []
                    loadedPath = path
                }
                if files != loaded {
                    files = loaded
                }
                if error != nil {
                    error = nil
                }
                let kept = expandedIDs.intersection(loaded.map(\.id))
                if kept != expandedIDs {
                    expandedIDs = kept
                }
                var loadedDiffs: [GitHiddenFile.ID: GitDiff] = [:]
                for file in loaded where kept.contains(file.id) {
                    loadedDiffs[file.id] = await diff(for: file, in: path)
                    try Task.checkCancellation()
                }
                if diffs != loadedDiffs {
                    diffs = loadedDiffs
                }
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
            }
        }
    }

    func toggleDiff(_ file: GitHiddenFile) {
        if expandedIDs.contains(file.id) {
            expandedIDs.remove(file.id)
            return
        }
        expandedIDs.insert(file.id)
        Task { await loadDiff(file) }
    }

    func hide(path: String, flag: GitHiddenFlag) {
        hide(paths: [path], flag: flag)
    }

    func hide(filesAt urls: [URL], flag: GitHiddenFlag) {
        guard urls.isEmpty == false else { return }
        let checkoutPath = checkout.checkoutPath
        let paths = urls.compactMap { GitHiddenFilePolicy.relativePath(of: $0.path, in: checkoutPath) }
        let outside = urls.count - paths.count
        if outside > 0 {
            activity.log("Cannot hide \(CountText.count(outside, "file"))", detail: "Only files inside \(checkoutPath.abbreviatingHome) can be hidden.", outcome: .failure)
        }
        hide(paths: paths, flag: flag)
    }

    private func hide(paths: [String], flag: GitHiddenFlag) {
        guard let first = paths.first else { return }
        let subject = paths.count == 1 ? (first as NSString).lastPathComponent : CountText.count(paths.count, "file")
        perform("Hide changes of \(subject) from git") { [git] checkoutPath in
            for path in paths {
                try await git.perform(.hide(path: path, flag: flag), in: checkoutPath)
            }
        }
    }

    func track(_ file: GitHiddenFile, mode: GitTrackMode) {
        perform(Self.trackTitle(file, mode: mode)) { [trackHiddenFile] checkoutPath in
            try await trackHiddenFile.execute(file, mode: mode, checkoutPath: checkoutPath)
        }
    }

    static func trackTitle(_ file: GitHiddenFile, mode: GitTrackMode) -> String {
        guard file.hasChanges else { return "Track \(file.fileName) again" }
        switch mode {
        case .keepChanges: return "Track \(file.fileName) again"
        case .stashChanges: return "Stash \(file.fileName) and track it again"
        case .discardChanges: return "Discard \(file.fileName) and track it again"
        }
    }

    private func loadDiff(_ file: GitHiddenFile) async {
        diffs[file.id] = await diff(for: file, in: checkout.checkoutPath)
    }

    private func diff(for file: GitHiddenFile, in path: String) async -> GitDiff {
        guard file.hasChanges else {
            return GitDiff(lines: [], droppedLines: 0, isBinary: false)
        }
        do {
            return try await repository.hiddenDiff(for: file, in: path)
        } catch {
            return GitDiff(lines: [error.localizedDescription], droppedLines: 0, isBinary: false)
        }
    }

    private func perform(_ title: String, work: @escaping (String) async throws -> Void) {
        guard busyTitle == nil else { return }
        let path = checkout.checkoutPath
        runner.run(
            title,
            detail: path.abbreviatingHome,
            onFailure: { [events] in events.post(.commandFailed) },
            completion: { [events] in events.post(.branchesChanged) },
            work: { try await work(path) }
        )
    }
}
