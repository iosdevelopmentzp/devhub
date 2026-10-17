import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class WorktreesStore: WorktreeLookup {
    var worktrees: [Worktree] = []
    var derivedDataSizes: [Worktree.ID: Int64] = [:]
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var isFetching = false
    private(set) var baseBranch = GitSettingsPolicy.baseRef(remote: GitSettingsPolicy.defaultRemote)
    private(set) var busyIDs: Set<Worktree.ID> = []
    private(set) var bootstrappingIDs: Set<Worktree.ID> = []

    @ObservationIgnored private let repository: WorktreeRepository
    @ObservationIgnored private let derivedData: any DerivedDataRepository
    @ObservationIgnored private let removeWorktree: RemoveWorktreeUseCase
    @ObservationIgnored private let cleanFinishedWorktrees: CleanFinishedWorktreesUseCase
    @ObservationIgnored private let createWorktree: CreateWorktreeUseCase
    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let config: ConfigStore
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?
    @ObservationIgnored private var loadedSettings = GitSettings.standard

    init(
        repository: WorktreeRepository,
        derivedData: any DerivedDataRepository,
        removeWorktree: RemoveWorktreeUseCase,
        cleanFinishedWorktrees: CleanFinishedWorktreesUseCase,
        createWorktree: CreateWorktreeUseCase,
        session: ProjectSession,
        config: ConfigStore,
        activity: ActivityLog,
        events: AppEvents
    ) {
        self.repository = repository
        self.derivedData = derivedData
        self.removeWorktree = removeWorktree
        self.cleanFinishedWorktrees = cleanFinishedWorktrees
        self.createWorktree = createWorktree
        self.session = session
        self.config = config
        self.activity = activity
        self.events = events
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                worktrees = []
                Task { await self.refresh() }
            case .branchesChanged, .worktreeCheckoutPrepared, .refreshRequested(.worktrees):
                Task { await self.refresh() }
            case .worktreeBootstrapping(let path, let isRunning):
                if isRunning {
                    bootstrappingIDs.insert(path)
                } else {
                    bootstrappingIDs.remove(path)
                }
            case .configChanged:
                guard gitSettings != loadedSettings else { return }
                Task { await self.refresh() }
            case .worktreesChanged, .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .mockSetChanged, .mergeRequestsChanged, .refreshRequested:
                break
            }
        }
    }

    var gitSettings: GitSettings {
        config.git
    }

    var mainWorktree: Worktree? {
        worktrees.first(where: \.isMain)
    }

    var mainCheckoutPath: String {
        mainWorktree?.path ?? ProjectPath(session.selectedProject.path).expanded
    }

    var availableCheckouts: [Worktree] {
        worktrees.filter { $0.isMissing == false }
    }

    func worktree(atPath path: String) -> Worktree? {
        worktrees.first { $0.path == path }
    }

    func checkoutPath(forBranch name: String) -> String? {
        BuildSourceResolver.checkoutPath(forBranch: name, in: worktrees, remote: gitSettings.remote)
    }

    func finishedWorktrees(excluding path: String?) -> [Worktree] {
        WorktreeCleanupPolicy.finished(in: worktrees, excluding: path)
    }

    var missingCount: Int {
        worktrees.filter(\.isMissing).count
    }

    var linkedDerivedDataSize: Int64 {
        derivedDataSize(of: worktrees.filter { $0.isMain == false })
    }

    func derivedDataSize(of targets: [Worktree]) -> Int64 {
        targets.reduce(0) { $0 + (derivedDataSizes[$1.id] ?? 0) }
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
            let projectPath = session.selectedProject.path
            let settings = gitSettings
            loadedSettings = settings
            do {
                async let list = repository.list(projectPath: projectPath, settings: settings)
                async let base = repository.baseBranch(projectPath: projectPath, remote: settings.remote)
                let (loaded, detected) = try await (list, base)
                try Task.checkCancellation()
                let baseName = settings.baseBranch ?? detected
                let changed = loaded != worktrees || baseName != baseBranch
                worktrees = loaded
                baseBranch = baseName
                error = nil
                if changed {
                    events.post(.worktreesChanged)
                }
            } catch {
                try Task.checkCancellation()
                let changed = worktrees.isEmpty == false
                worktrees = []
                self.error = error.localizedDescription
                if changed {
                    events.post(.worktreesChanged)
                }
            }
            let sizes = await derivedDataSizes(for: availableCheckouts.map(\.path))
            try Task.checkCancellation()
            derivedDataSizes = sizes
        }
    }

    func fetchAndRefresh() {
        guard isFetching == false else { return }
        isFetching = true
        let path = session.selectedProject.path
        let remote = gitSettings.remote
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.fetch(projectPath: path, remote: remote)
            } catch {
                activity.log("git fetch failed", detail: error.localizedDescription, outcome: .failure)
            }
            isFetching = false
            await refresh()
        }
    }

    // MARK: Changing

    func delete(id: Worktree.ID, deleteDerivedData: Bool, deleteBranch: Bool) {
        guard let worktree = worktree(atPath: id), worktree.isMain == false else { return }
        busyIDs.insert(id)
        let projectPath = session.selectedProject.path
        let size = derivedDataSizes[id] ?? 0
        Task { [weak self] in
            guard let self else { return }
            let summary = await removeWorktree.execute(
                worktree,
                projectPath: projectPath,
                deleteDerivedData: deleteDerivedData,
                deleteBranch: deleteBranch,
                derivedDataSize: size
            )
            busyIDs.remove(id)
            activity.log(summary.title, detail: summary.detail, outcome: summary.outcome)
            await refresh()
        }
    }

    func clean(_ targets: [Worktree]) {
        guard targets.isEmpty == false else { return }
        busyIDs.formUnion(targets.map(\.id))
        let projectPath = session.selectedProject.path
        let sizes = derivedDataSizes
        Task { [weak self] in
            guard let self else { return }
            let report = await cleanFinishedWorktrees.execute(
                targets,
                projectPath: projectPath,
                derivedDataSizes: sizes
            ) { [weak self] id in
                await self?.finishRemoval(id)
            }
            let failures = report.failedNames
            let detail = "\(report.removedCount) removed, \(ByteFormat.text(report.derivedDataBytes)) DerivedData" + (failures.isEmpty ? "" : " · failed: \(failures.joined(separator: ", "))")
            activity.log("Cleaned finished worktrees", detail: detail, outcome: failures.isEmpty ? .success : .failure)
            await refresh()
        }
    }

    func prune() {
        let path = session.selectedProject.path
        let stale = worktrees.filter(\.isMissing)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.prune(projectPath: path)
                activity.log("Pruned \(stale.count) worktree(s)", detail: stale.map(\.displayName).joined(separator: ", "), outcome: .success)
            } catch {
                activity.log("Prune failed", detail: error.localizedDescription, outcome: .failure)
            }
            await refresh()
        }
    }

    func create(branch: String) async -> Worktree? {
        do {
            guard let created = try await createWorktree.execute(
                branch: branch,
                base: baseBranch,
                projectPath: session.selectedProject.path,
                settings: gitSettings
            ) else { return nil }
            activity.log("Created worktree", detail: "\(created.branch) · \(created.path.abbreviatingHome)", outcome: .success)
            await refresh()
            return worktree(atPath: created.path)
        } catch {
            activity.log("Could not create worktree", detail: error.localizedDescription, outcome: .failure)
            return nil
        }
    }

    func createAndBootstrap(branch: String) async -> Bool {
        guard let worktree = await create(branch: branch) else { return false }
        if worktree.needsBootstrap || (gitSettings.worktrees.bootstrap != nil && gitSettings.worktrees.bootstrapMarker == nil) {
            bootstrap(id: worktree.id)
        }
        return true
    }

    func bootstrap(id: Worktree.ID) {
        guard let worktree = worktree(atPath: id), bootstrappingIDs.contains(id) == false, let script = gitSettings.worktrees.bootstrap else { return }
        Task { [weak self] in
            guard let self else { return }
            try? await runBootstrap(worktree, script: script)
            await refresh()
        }
    }

    private func runBootstrap(_ worktree: Worktree, script: String) async throws {
        bootstrappingIDs.insert(worktree.id)
        defer { bootstrappingIDs.remove(worktree.id) }
        do {
            try await repository.bootstrap(worktreePath: worktree.path, script: script) { _ in }
            activity.log("Bootstrapped \(worktree.displayName)", detail: "\(script) finished", outcome: .success)
        } catch {
            activity.log("Bootstrap failed: \(worktree.displayName)", detail: "\(error.localizedDescription) Full output in the Output panel.", outcome: .failure)
            throw error
        }
    }

    // MARK: Private

    private func derivedDataSizes(for checkouts: [String]) async -> [Worktree.ID: Int64] {
        let derivedData = derivedData
        var sizes: [Worktree.ID: Int64] = [:]
        await withTaskGroup(of: (String, Int64?).self) { group in
            for path in checkouts {
                group.addTask {
                    guard let folder = derivedData.folder(forCheckout: path) else { return (path, nil) }
                    return (path, await derivedData.size(of: folder))
                }
            }
            for await (path, size) in group {
                sizes[path] = size
            }
        }
        return sizes.compactMapValues { $0 }
    }

    private func finishRemoval(_ id: Worktree.ID) {
        busyIDs.remove(id)
    }
}
