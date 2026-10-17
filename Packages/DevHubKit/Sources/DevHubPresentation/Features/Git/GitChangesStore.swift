import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class GitChangesStore {
    private(set) var changes: [GitFileChange] = []
    private(set) var diffs: [GitFileChange.ID: GitDiff] = [:]
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var loadedPath: String?
    var expandedIDs: Set<GitFileChange.ID> = []
    var message = ""
    var amend = false

    @ObservationIgnored private let repository: any GitChangesRepository
    @ObservationIgnored private let git: any GitRepository
    @ObservationIgnored private let discardChange: DiscardChangeUseCase
    @ObservationIgnored private let commitChanges: CommitUseCase
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let runner: ActionRunner
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(
        repository: any GitChangesRepository,
        git: any GitRepository,
        discardChange: DiscardChangeUseCase,
        commitChanges: CommitUseCase,
        checkout: any CheckoutContext,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.git = git
        self.discardChange = discardChange
        self.commitChanges = commitChanges
        self.checkout = checkout
        self.activity = activity
        self.events = events
        runner = ActionRunner(activity: activity)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .branchesChanged:
                guard loadedPath != nil, busyTitle == nil else { return }
                Task { await self.refresh() }
            case .projectChanged:
                changes = []
                diffs = [:]
                loadedPath = nil
            case .worktreesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .mergeRequestsChanged, .configChanged, .refreshRequested:
                break
            }
        }
    }

    var busyTitle: String? {
        runner.busyTitle
    }

    var staged: [GitFileChange] { changes.filter { $0.area == .staged } }
    var unstaged: [GitFileChange] { changes.filter { $0.area == .unstaged } }
    var untracked: [GitFileChange] { changes.filter { $0.area == .untracked } }
    var conflicted: [GitFileChange] { changes.filter { $0.area == .conflicted } }

    var fileCount: Int {
        Set(changes.map(\.path)).count
    }

    var canCommit: Bool {
        busyTitle == nil && message.trimmed.isEmpty == false && (staged.isEmpty == false || amend) && conflicted.isEmpty
    }

    var suggestedPrefix: String? {
        checkout.currentBranch.flatMap { TicketPrefix.prefix(forBranch: $0, ticket: checkout.gitSettings.ticket(fallbackURL: "")) }
    }

    // MARK: Reading

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
                let loaded = try await repository.changes(in: path)
                try Task.checkCancellation()
                if loadedPath != path {
                    expandedIDs = []
                }
                if changes != loaded {
                    changes = loaded
                }
                if loadedPath != path {
                    loadedPath = path
                }
                if error != nil {
                    error = nil
                }
                let kept = expandedIDs.intersection(loaded.map(\.id))
                if kept != expandedIDs {
                    expandedIDs = kept
                }
                var loadedDiffs: [GitFileChange.ID: GitDiff] = [:]
                for change in loaded where kept.contains(change.id) {
                    loadedDiffs[change.id] = await diff(for: change, in: path)
                    try Task.checkCancellation()
                }
                if diffs != loadedDiffs {
                    diffs = loadedDiffs
                }
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
            }
            if message.isEmpty, let prefix = suggestedPrefix {
                message = prefix
            }
        }
    }

    func toggleDiff(_ change: GitFileChange) {
        if expandedIDs.contains(change.id) {
            expandedIDs.remove(change.id)
            return
        }
        expandedIDs.insert(change.id)
        Task { await loadDiff(change) }
    }

    private func loadDiff(_ change: GitFileChange) async {
        diffs[change.id] = await diff(for: change, in: checkout.checkoutPath)
    }

    private func diff(for change: GitFileChange, in path: String) async -> GitDiff {
        do {
            return try await repository.diff(for: change, in: path)
        } catch {
            return GitDiff(lines: [error.localizedDescription], droppedLines: 0, isBinary: false)
        }
    }

    // MARK: Index

    func stage(_ change: GitFileChange) {
        run("Stage \(change.fileName)", .stage(path: change.path))
    }

    func unstage(_ change: GitFileChange) {
        run("Unstage \(change.fileName)", .unstage(path: change.path))
    }

    func discard(_ change: GitFileChange) {
        let title = change.area == .untracked ? "Delete \(change.fileName)" : "Discard changes in \(change.fileName)"
        perform(title) { [discardChange] path in
            try await discardChange.execute(change, checkoutPath: path)
        }
    }

    func stageAll() {
        run("Stage all", .stageAll)
    }

    func unstageAll() {
        run("Unstage all", .unstageAll)
    }

    // MARK: Commit

    func commit(thenPush: Bool) {
        guard canCommit else { return }
        let text = message.trimmed
        let isAmend = amend
        let branch = checkout.currentBranch
        let upstream = checkout.currentUpstream
        let remote = checkout.gitSettings.remote
        var pushResult = CommitUseCase.PushResult.skipped
        perform(isAmend ? "Amend commit" : "Commit") { [commitChanges] path in
            pushResult = try await commitChanges.execute(
                message: text,
                amend: isAmend,
                thenPush: thenPush,
                branch: branch,
                upstream: upstream,
                remote: remote,
                checkoutPath: path
            )
        } onSuccess: { [weak self] path in
            guard let self else { return }
            message = suggestedPrefix ?? ""
            amend = false
            logPush(pushResult, path: path)
        }
    }

    // MARK: Runner

    private func logPush(_ result: CommitUseCase.PushResult, path: String) {
        switch result {
        case .skipped:
            break
        case .pushed(let branch):
            activity.log("Push \(branch)", detail: path.abbreviatingHome, outcome: .success)
        case .failed(let branch, let error):
            activity.log("Push \(branch) failed", detail: error.localizedDescription, outcome: .failure)
            events.post(.commandFailed)
        }
    }

    private func run(_ title: String, _ command: GitCommand) {
        perform(title) { [git] path in
            try await git.perform(command, in: path)
        }
    }

    private func perform(
        _ title: String,
        work: @escaping (String) async throws -> Void,
        onSuccess: ((String) -> Void)? = nil
    ) {
        guard busyTitle == nil else { return }
        let path = checkout.checkoutPath
        runner.run(
            title,
            detail: path.abbreviatingHome,
            onSuccess: { onSuccess?(path) },
            onFailure: { [events] in events.post(.commandFailed) },
            completion: { [events] in events.post(.branchesChanged) },
            work: { try await work(path) }
        )
    }
}
