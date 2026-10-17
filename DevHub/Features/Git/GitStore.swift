import Foundation
import Observation

@MainActor
@Observable
final class GitStore {
    private(set) var status: GitStatus = .empty
    private(set) var details: CheckoutDetails = .empty
    private(set) var branches: BranchSnapshot = .empty
    private(set) var history: [GitCommit] = []
    private(set) var selectedCheckout: String?
    private(set) var segment: GitSegment
    private(set) var isRefreshing = false
    private(set) var error: String?
    private(set) var busyTitle: String?
    private(set) var confirmation: GitConfirmation?
    private(set) var pullRequest: PullRequestLoad?
    private(set) var expandedDiff: String?
    private(set) var diffs: [String: GitDiff] = [:]
    var commitMessage = ""
    var amend = false

    @ObservationIgnored let provider: GitRepositoryProviding
    @ObservationIgnored let hosting: PullRequestProviding
    @ObservationIgnored let executor: GitExecutor
    @ObservationIgnored let session: ProjectSession
    @ObservationIgnored let config: ConfigStore
    @ObservationIgnored let worktrees: WorktreesStore
    @ObservationIgnored let events: AppEvents
    @ObservationIgnored let activity: ActivityLog
    @ObservationIgnored let toaster: Toaster
    @ObservationIgnored let projectActions: ProjectActions
    @ObservationIgnored let preferences: AppPreferences
    @ObservationIgnored var isPosting = false
    @ObservationIgnored var needsReload = false
    @ObservationIgnored var pullRequestCache: [String: (date: Date, load: PullRequestLoad)] = [:]
    @ObservationIgnored var lastPrefix: String?
    @ObservationIgnored var loadedFor: String?

    init(
        provider: GitRepositoryProviding,
        hosting: PullRequestProviding,
        executor: GitExecutor,
        session: ProjectSession,
        config: ConfigStore,
        worktrees: WorktreesStore,
        events: AppEvents,
        activity: ActivityLog,
        toaster: Toaster,
        projectActions: ProjectActions,
        preferences: AppPreferences
    ) {
        self.provider = provider
        self.hosting = hosting
        self.executor = executor
        self.session = session
        self.config = config
        self.worktrees = worktrees
        self.events = events
        self.activity = activity
        self.toaster = toaster
        self.projectActions = projectActions
        self.preferences = preferences
        segment = preferences.string(.gitSegment).flatMap(GitSegment.init(rawValue:)) ?? .local
        events.subscribe { [weak self] event in
            guard let self else { return }
            handle(event)
        }
    }

    var checkoutPath: String { selectedCheckout ?? session.project?.path ?? "" }

    var currentBranch: String? { status.branch }

    var baseBranch: String { config.effective?.baseBranch ?? "origin/main" }

    var baseLocalName: String {
        baseBranch.hasPrefix("origin/") ? String(baseBranch.dropFirst("origin/".count)) : baseBranch
    }

    var isBusy: Bool { busyTitle != nil }

    var hasUpstream: Bool { status.upstream != nil }

    var checkouts: [GitCheckout] {
        var list = worktrees.worktrees.filter { $0.isMissing == false }.map {
            GitCheckout(path: $0.path, title: $0.isMain ? "Main checkout" : $0.title, isMain: $0.isMain)
        }
        if list.isEmpty, let main = session.project?.path {
            list = [GitCheckout(path: main, title: "Main checkout", isMain: true)]
        }
        return list
    }

    var currentCheckout: GitCheckout? {
        checkouts.first { $0.path == checkoutPath } ?? checkouts.first
    }

    var branchNames: [String] {
        branches.local.map(\.name) + branches.remote.map(\.name).filter { branches.hasLocal($0) == false }
    }

    var grouped: [(group: GitChange.Group, changes: [GitChange])] {
        GitChange.Group.allCases.compactMap { group in
            let list = status.changes.filter { $0.groups.contains(group) }
            return list.isEmpty ? nil : (group, list)
        }
    }

    var stagedCount: Int {
        status.changes.filter(\.hasStagedChange).count
    }

    func refresh(reloadCheckouts: Bool = true) async {
        if isRefreshing {
            needsReload = true
            return
        }
        guard session.project != nil else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        repeat {
            needsReload = false
            await load(reloadCheckouts: reloadCheckouts)
        } while needsReload
    }

    func announceChange() {
        isPosting = true
        events.post(.branchesChanged)
        isPosting = false
    }

    private func load(reloadCheckouts: Bool) async {
        loadedFor = session.project?.path
        let path = checkoutPath
        let base = baseBranch
        async let checkoutsDone: Void = reloadCheckouts ? worktrees.refreshCheckouts() : ()
        async let loadedDetails = provider.details(at: path, base: base)
        async let loadedBranches = provider.branches(at: path, base: base)
        async let loadedHistory = provider.history(at: path, limit: 150)
        var failure: String?
        do {
            let newStatus = try await provider.status(at: path)
            guard path == checkoutPath else { return }
            status = newStatus
        } catch {
            failure = error.localizedDescription
        }
        details = await loadedDetails
        do {
            branches = try await loadedBranches
        } catch {
            failure = failure ?? error.localizedDescription
        }
        history = (try? await loadedHistory) ?? []
        await checkoutsDone
        if selectedCheckout != nil, checkouts.contains(where: { $0.path == selectedCheckout }) == false {
            selectedCheckout = nil
        }
        error = failure
        if let failure {
            activity.log("Git refresh failed", detail: failure, outcome: .failure)
        }
        session.setCheckout(path: selectedCheckout, branch: status.branch)
        applyCommitPrefix()
        await session.refresh()
        await loadPullRequest(force: false)
    }

    private func handle(_ event: AppEvent) {
        guard isPosting == false else { return }
        switch event {
        case .projectChanged:
            if loadedFor != session.project?.path {
                reset()
            }
            Task { await refresh() }
        case .worktreesChanged:
            Task { await refresh(reloadCheckouts: false) }
        case .branchesChanged, .configChanged:
            Task { await refresh() }
        case .simulatorsChanged, .commandFailed:
            break
        }
    }

    private func reset() {
        status = .empty
        details = .empty
        branches = .empty
        history = []
        selectedCheckout = nil
        confirmation = nil
        pullRequest = nil
        expandedDiff = nil
        diffs = [:]
        commitMessage = ""
        lastPrefix = nil
        amend = false
        pullRequestCache = [:]
    }
}

extension GitStore {
    func selectSegment(_ value: GitSegment) {
        segment = value
        preferences.set(value.rawValue, for: .gitSegment)
    }

    func selectCheckout(_ path: String?) {
        let target = path == session.project?.path ? nil : path
        guard target != selectedCheckout else { return }
        selectedCheckout = target
        status = .empty
        details = .empty
        history = []
        expandedDiff = nil
        diffs = [:]
        confirmation = nil
        pullRequest = nil
        commitMessage = ""
        lastPrefix = nil
        amend = false
        session.setCheckout(path: target, branch: nil)
        Task { await refresh(reloadCheckouts: false) }
    }

    func setBusy(_ title: String?) {
        busyTitle = title
    }

    func setConfirmation(_ value: GitConfirmation?) {
        confirmation = value
    }

    func setPullRequest(_ value: PullRequestLoad?) {
        pullRequest = value
    }

    func setExpandedDiff(_ key: String?) {
        expandedDiff = key
    }

    func storeDiff(_ diff: GitDiff, for key: String) {
        diffs[key] = diff
    }

    func clearDiffs() {
        diffs = [:]
        expandedDiff = nil
    }

    private func applyCommitPrefix() {
        guard let branch = status.branch else { return }
        let fresh = CommitPrefix.make(
            branch: branch,
            pattern: config.config.git?.commitPrefix?.pattern,
            format: config.config.git?.commitPrefix?.format
        )
        guard commitMessage.isEmpty || commitMessage == lastPrefix else { return }
        commitMessage = fresh
        lastPrefix = fresh
    }
}
