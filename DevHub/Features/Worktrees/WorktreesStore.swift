import Foundation
import Observation

@MainActor
@Observable
final class WorktreesStore {
    private(set) var worktrees: [WorktreeInfo] = []
    private(set) var branches: BranchSnapshot = .empty
    private(set) var derivedData: DerivedDataReport = .empty
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var workingTitle: String?
    private(set) var busyPaths: Set<String> = []
    private(set) var pendingDelete: String?
    private(set) var pendingClean: [WorktreeInfo]?
    private(set) var creationError: String?
    private(set) var buildSourcePath: String?

    @ObservationIgnored let provider: WorktreeProviding
    @ObservationIgnored let executor: GitExecutor
    @ObservationIgnored let git: GitRepositoryProviding
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let projectActions: ProjectActions
    @ObservationIgnored var isPosting = false
    @ObservationIgnored private var needsReload = false
    @ObservationIgnored private var wantsSizes = false
    @ObservationIgnored private var loadedFor: String?

    init(
        provider: WorktreeProviding,
        git: GitRepositoryProviding,
        executor: GitExecutor,
        session: ProjectSession,
        config: ConfigStore,
        events: AppEvents,
        activity: ActivityLog,
        toaster: Toaster,
        projectActions: ProjectActions
    ) {
        self.provider = provider
        self.git = git
        self.executor = executor
        self.session = session
        self.config = config
        self.events = events
        self.activity = activity
        self.toaster = toaster
        self.projectActions = projectActions
        events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var baseBranch: String { config.effective?.baseBranch ?? "origin/main" }

    var sections: WorktreeSections { WorktreeSections(worktrees) }

    var mainPath: String? { session.project?.path }

    var worktreeSettings: WorktreesConfig? { config.config.git?.worktrees }

    func worktree(forBranch branch: String) -> WorktreeInfo? {
        worktrees.first { $0.branch == branch && $0.isMissing == false }
    }

    func derivedSize(of worktree: WorktreeInfo) -> Int64? {
        derivedData.entries[worktree.path]?.bytes
    }

    func setBuildSource(_ path: String?) {
        buildSourcePath = path
    }

    func refresh() async {
        await reload(includesSizes: true)
    }

    func refreshCheckouts() async {
        await reload(includesSizes: false)
    }

    private func reload(includesSizes: Bool) async {
        wantsSizes = wantsSizes || includesSizes
        if isLoading {
            needsReload = true
            return
        }
        guard let main = mainPath else {
            worktrees = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        repeat {
            needsReload = false
            let withSizes = wantsSizes
            wantsSizes = false
            await load(main: main, includesSizes: withSizes)
        } while needsReload && mainPath == main
    }

    func announceChange() {
        isPosting = true
        events.post(.worktreesChanged)
        isPosting = false
    }

    private func load(main: String, includesSizes: Bool) async {
        loadedFor = main
        do {
            let base = baseBranch
            let listed = try await provider.list(at: main, base: base, settings: worktreeSettings)
            guard mainPath == main else { return }
            worktrees = listed
            error = nil
            branches = (try? await git.branches(at: main, base: base)) ?? branches
            if includesSizes {
                let paths = listed.filter { $0.isMissing == false }.map(\.path)
                Task { await loadDerivedData(for: paths, main: main) }
            }
        } catch {
            self.error = error.localizedDescription
            activity.log("Worktree list failed", detail: error.localizedDescription, outcome: .failure)
        }
    }

    private func loadDerivedData(for paths: [String], main: String) async {
        let report = await provider.derivedData(for: paths)
        guard mainPath == main else { return }
        derivedData = report
    }


    private func handle(_ event: AppEvent) {
        guard isPosting == false else { return }
        switch event {
        case .projectChanged:
            if loadedFor != mainPath {
                worktrees = []
                branches = .empty
                derivedData = .empty
                pendingDelete = nil
                pendingClean = nil
            }
            Task { await refreshCheckouts() }
        case .worktreesChanged, .branchesChanged, .configChanged:
            Task { await refreshCheckouts() }
        case .simulatorsChanged, .commandFailed:
            break
        }
    }
}

extension WorktreesStore {
    func markBusy(_ path: String, _ isBusy: Bool) {
        if isBusy {
            busyPaths.insert(path)
        } else {
            busyPaths.remove(path)
        }
    }

    func setWorking(_ title: String?) {
        workingTitle = title
    }

    func setPendingDelete(_ path: String?) {
        pendingDelete = path
    }

    func setPendingClean(_ list: [WorktreeInfo]?) {
        pendingClean = list
    }

    func setCreationError(_ message: String?) {
        creationError = message
    }
}
