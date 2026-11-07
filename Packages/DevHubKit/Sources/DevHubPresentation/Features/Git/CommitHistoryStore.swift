import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class CommitHistoryStore {
    enum Scope: String, CaseIterable {
        case branch = "This branch"
        case all = "All"
    }

    var scope: Scope {
        didSet {
            guard scope != oldValue else { return }
            store.set(scope.rawValue, forKey: Self.scopeKey)
        }
    }
    private(set) var branchCommits: [GitCommit] = []
    private(set) var branchError: String?
    private(set) var hasLoadedBranch = false
    private(set) var reflog: [GitReflogEntry] = []
    private(set) var reflogError: String?
    private(set) var hasLoadedReflog = false
    private(set) var expandedRow: String?
    private(set) var files: [String: [GitCommitFile]] = [:]
    private(set) var fileErrors: [String: String] = [:]
    private(set) var expandedFiles: Set<CommitFileKey> = []
    private(set) var diffs: [CommitFileKey: GitDiff] = [:]
    private(set) var containingBranches: [String: [GitCommitRef]] = [:]
    private(set) var stashHashes: Set<String> = []

    @ObservationIgnored private let repository: any GitChangesRepository
    @ObservationIgnored private let checkout: any CheckoutContext
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private let reflogTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let scopeKey = "git.historyScope"

    init(repository: any GitChangesRepository, checkout: any CheckoutContext, activity: ActivityLog, events: AppEvents, store: any KeyValueStore) {
        self.repository = repository
        self.checkout = checkout
        self.activity = activity
        self.store = store
        scope = store.string(forKey: Self.scopeKey).flatMap(Scope.init(rawValue:)) ?? .all
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                branchCommits = []
                branchError = nil
                hasLoadedBranch = false
                reflog = []
                reflogError = nil
                hasLoadedReflog = false
                expandedRow = nil
                files = [:]
                fileErrors = [:]
                expandedFiles = []
                diffs = [:]
                containingBranches = [:]
                stashHashes = []
            case .branchesChanged:
                containingBranches = [:]
                if hasLoadedBranch, scope == .branch {
                    Task { await self.refreshBranchCommits() }
                }
                if hasLoadedReflog {
                    Task { await self.refreshReflog() }
                }
            default:
                break
            }
        }
    }

    func refreshBranchCommits() async {
        await refreshTask.run { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await repository.branchCommits(base: checkout.baseRef, remote: checkout.gitSettings.remote, in: checkout.checkoutPath)
                try Task.checkCancellation()
                if branchCommits != loaded {
                    branchCommits = loaded
                }
                branchError = nil
            } catch {
                try Task.checkCancellation()
                branchError = error.localizedDescription
            }
            hasLoadedBranch = true
        }
    }

    func refreshReflog() async {
        await reflogTask.run { [weak self] in
            guard let self else { return }
            do {
                let loaded = try await repository.reflog(in: checkout.checkoutPath)
                try Task.checkCancellation()
                if reflog != loaded {
                    reflog = loaded
                }
                reflogError = nil
            } catch {
                try Task.checkCancellation()
                reflogError = error.localizedDescription
            }
            hasLoadedReflog = true
        }
    }

    func toggleRow(_ rowID: String, hash: String) {
        guard expandedRow != rowID else {
            expandedRow = nil
            return
        }
        expandedRow = rowID
        if containingBranches[hash] == nil {
            Task { await loadContainingBranches(hash) }
        }
        guard files[hash] == nil else { return }
        Task { await loadFiles(hash) }
    }

    func toggleStash(_ stash: GitStash) {
        let rowID = Self.stashRowID(stash)
        guard expandedRow != rowID else {
            expandedRow = nil
            return
        }
        expandedRow = rowID
        stashHashes.insert(stash.hash)
        guard files[stash.hash] == nil else { return }
        Task { await loadFiles(stash.hash) }
    }

    static func stashRowID(_ stash: GitStash) -> String {
        "stash:\(stash.hash)"
    }

    func loadFiles(_ hash: String) async {
        fileErrors[hash] = nil
        do {
            files[hash] = stashHashes.contains(hash)
                ? try await repository.stashFiles(hash: hash, in: checkout.checkoutPath)
                : try await repository.commitFiles(hash: hash, in: checkout.checkoutPath)
        } catch {
            fileErrors[hash] = error.localizedDescription
        }
    }

    private func loadContainingBranches(_ hash: String) async {
        do {
            containingBranches[hash] = try await repository.branchesContaining(hash: hash, in: checkout.checkoutPath)
        } catch {
            activity.log("Cannot read the branches of \(hash.prefix(9))", detail: error.localizedDescription, outcome: .failure)
        }
    }

    func toggleFile(_ file: GitCommitFile, of hash: String) {
        let key = CommitFileKey(hash: hash, path: file.path)
        guard expandedFiles.contains(key) == false else {
            expandedFiles.remove(key)
            return
        }
        expandedFiles.insert(key)
        guard diffs[key] == nil else { return }
        Task { await loadDiff(file, key: key) }
    }

    private func loadDiff(_ file: GitCommitFile, key: CommitFileKey) async {
        do {
            diffs[key] = stashHashes.contains(key.hash)
                ? try await repository.stashDiff(hash: key.hash, file: file, in: checkout.checkoutPath)
                : try await repository.commitDiff(hash: key.hash, file: file, in: checkout.checkoutPath)
        } catch {
            expandedFiles.remove(key)
            activity.log("Cannot read the diff of \(file.fileName)", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
