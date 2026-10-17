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
            case .branchesChanged:
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
                let loaded = try await repository.branchCommits(base: checkout.baseRef, in: checkout.checkoutPath)
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
        guard files[hash] == nil else { return }
        Task { await loadFiles(hash) }
    }

    func loadFiles(_ hash: String) async {
        fileErrors[hash] = nil
        do {
            files[hash] = try await repository.commitFiles(hash: hash, in: checkout.checkoutPath)
        } catch {
            fileErrors[hash] = error.localizedDescription
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
            diffs[key] = try await repository.commitDiff(hash: key.hash, file: file, in: checkout.checkoutPath)
        } catch {
            expandedFiles.remove(key)
            activity.log("Cannot read the diff of \(file.fileName)", detail: error.localizedDescription, outcome: .failure)
        }
    }
}
