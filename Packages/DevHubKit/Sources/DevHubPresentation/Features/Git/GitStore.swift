import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class GitStore: CheckoutContext {
    enum Section: String, CaseIterable {
        case local = "Local"
        case remote = "Remote"
        case history = "History"
        case reflog = "Reflog"
        case changes = "Changes"
        case stash = "Stash"
    }

    var state: GitRepositoryState?
    var section: Section {
        didSet {
            guard section != oldValue else { return }
            store.set(section.rawValue, forKey: Self.sectionKey)
        }
    }
    private(set) var error: String?
    private(set) var isLoading = false
    private(set) var selectedCheckoutPath: String?
    private(set) var bulkDelete: BulkProgress?
    var isMergedCollapsed: Bool {
        didSet {
            guard isMergedCollapsed != oldValue else { return }
            store.encode(isMergedCollapsed, forKey: Self.mergedCollapsedKey)
        }
    }

    @ObservationIgnored private let repository: any GitRepository
    @ObservationIgnored private let updateBranch: UpdateBranchUseCase
    @ObservationIgnored private let updateBaseBranch: UpdateBaseBranchUseCase
    @ObservationIgnored private let checkOutRemoteBranch: CheckOutRemoteBranchUseCase
    @ObservationIgnored private let rebaseOnBaseBranch: RebaseOnBaseUseCase
    @ObservationIgnored private let switchBranch: SwitchBranchUseCase
    @ObservationIgnored private let pushCurrentBranch: PushCurrentBranchUseCase
    @ObservationIgnored private let worktrees: any WorktreeLookup
    @ObservationIgnored private let runner: ActionRunner
    @ObservationIgnored private let activity: ActivityLog
    @ObservationIgnored private let events: AppEvents
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var isPostingBranchesChanged = false
    @ObservationIgnored private let refreshTask = RefreshTask()
    @ObservationIgnored private var subscription: SubscriptionToken?

    private static let sectionKey = "git.section"
    private static let mergedCollapsedKey = "git.mergedCollapsed"

    init(
        repository: any GitRepository,
        updateBranch: UpdateBranchUseCase,
        updateBaseBranch: UpdateBaseBranchUseCase,
        checkOutRemoteBranch: CheckOutRemoteBranchUseCase,
        rebaseOnBaseBranch: RebaseOnBaseUseCase,
        switchBranch: SwitchBranchUseCase,
        pushCurrentBranch: PushCurrentBranchUseCase,
        worktrees: any WorktreeLookup,
        activity: ActivityLog,
        events: AppEvents,
        store: any KeyValueStore
    ) {
        self.repository = repository
        self.updateBranch = updateBranch
        self.updateBaseBranch = updateBaseBranch
        self.checkOutRemoteBranch = checkOutRemoteBranch
        self.rebaseOnBaseBranch = rebaseOnBaseBranch
        self.switchBranch = switchBranch
        self.pushCurrentBranch = pushCurrentBranch
        self.worktrees = worktrees
        self.events = events
        self.store = store
        runner = ActionRunner(activity: activity)
        self.activity = activity
        isMergedCollapsed = store.decode(Bool.self, forKey: Self.mergedCollapsedKey) ?? true
        section = store.string(forKey: Self.sectionKey).flatMap(Section.init(rawValue:)) ?? .local
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            switch event {
            case .projectChanged:
                state = nil
                selectedCheckoutPath = nil
            case .worktreesChanged:
                guard state != nil, isBusy == false else { return }
                Task { await self.refresh() }
            case .branchesChanged:
                guard isPostingBranchesChanged == false, isBusy == false else { return }
                Task { await self.refresh() }
            case .refreshRequested(.git):
                guard state != nil, isBusy == false else { return }
                Task { await self.refresh() }
            case .simulatorsChanged, .commandFailed, .buildStarted, .buildFinished, .appLaunched, .worktreeCheckoutPrepared, .worktreeBootstrapping, .mockSetChanged, .pullRequestsChanged, .configChanged, .appStateReported, .refreshRequested:
                break
            }
        }
    }

    var busyTitle: String? {
        runner.busyTitle
    }

    var checkoutPath: String {
        selectedCheckoutPath ?? worktrees.mainCheckoutPath
    }

    var snapshot: GitSnapshot? {
        state?.snapshot
    }

    var currentBranch: String? {
        snapshot?.branch
    }

    var currentUpstream: String? {
        snapshot?.upstream
    }

    var webURL: URL? {
        snapshot?.webURL
    }

    var gitSettings: GitSettings {
        worktrees.gitSettings
    }

    var remote: String {
        gitSettings.remote
    }

    var baseRef: String {
        snapshot?.baseBranch ?? gitSettings.baseBranch ?? GitSettingsPolicy.baseRef(remote: remote)
    }

    var baseName: String {
        BranchName(baseRef, remote: remote).local
    }

    var isBusy: Bool {
        runner.busyTitle != nil || bulkDelete != nil
    }

    var localBranchNames: Set<String> {
        Set((state?.localBranches ?? []).map(\.name))
    }

    var hasLocalChanges: Bool {
        (snapshot?.changedFiles ?? 0) > 0
    }

    var isMainCheckoutClean: Bool {
        selectedCheckoutPath == nil && snapshot?.changedFiles == 0
    }

    func worktree(atPath path: String?) -> Worktree? {
        guard let path else { return nil }
        return worktrees.worktree(atPath: path)
    }

    func checkoutPath(forBranch name: String) -> String? {
        worktrees.checkoutPath(forBranch: name)
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
            do {
                let loaded = try await repository.state(checkoutPath: checkoutPath, mainPath: worktrees.mainCheckoutPath, settings: gitSettings)
                try Task.checkCancellation()
                if loaded != state {
                    state = loaded
                }
                if error != nil {
                    error = nil
                }
            } catch {
                try Task.checkCancellation()
                self.error = error.localizedDescription
            }
        }
    }

    func selectCheckout(_ path: String?) {
        selectedCheckoutPath = path == worktrees.mainCheckoutPath ? nil : path
        state = nil
        Task { await refresh() }
    }

    // MARK: Remote

    func fetch() {
        run("Fetch", .fetchPrune(remote: remote))
    }

    func fetchIfStale(everyMinutes minutes: Int, now: Date) {
        guard let snapshot, isBusy == false else { return }
        guard FetchPolicy.shouldFetch(lastFetch: snapshot.lastFetch, everyMinutes: minutes, now: now) else { return }
        fetch()
    }

    func pull() {
        run("Pull", .pullFastForward)
    }

    func push() {
        guard let branch = currentBranch else { return }
        let upstream = currentUpstream
        let path = checkoutPath
        let remote = remote
        perform("Push \(branch)", in: path) { [pushCurrentBranch] in
            try await pushCurrentBranch.execute(branch: branch, upstream: upstream, remote: remote, checkoutPath: path)
        }
    }

    func forcePush() {
        guard let branch = currentBranch else { return }
        run("Force push \(branch)", .forcePushWithLease(branch: branch, remote: remote))
    }

    func rebaseOnBase() {
        let base = baseRef
        let name = baseName
        let path = checkoutPath
        let remote = remote
        perform("Rebase on \(base)", in: path) { [rebaseOnBaseBranch] in
            try await rebaseOnBaseBranch.execute(baseName: name, baseRef: base, remote: remote, checkoutPath: path)
        }
    }

    func continueRebase() {
        run("Continue rebase", .continueRebase)
    }

    func abortOperation() {
        guard let operation = snapshot?.operation else { return }
        run("Abort \(operation)", .abort(operation: operation))
    }

    // MARK: Branches

    func update(_ branch: GitBranch) {
        let remote = remote
        let plan = UpdateBranchUseCase.plan(branch: branch, currentBranch: currentBranch, remote: remote)
        let path = checkoutPath
        perform(updateTitle(plan, branch: branch), in: directory(for: plan)) { [updateBranch] in
            try await updateBranch.execute(plan, branch: branch, remote: remote, checkoutPath: path)
        }
    }

    func updateBase() {
        let plan = UpdateBaseBranchUseCase.plan(
            baseName: baseName,
            localBranches: state?.localBranches ?? [],
            currentBranch: currentBranch,
            remote: remote
        )
        let path = checkoutPath
        let remote = remote
        let title: String
        let directory: String
        switch plan {
        case .updateLocal(let branch, let branchPlan):
            title = updateTitle(branchPlan, branch: branch)
            directory = self.directory(for: branchPlan)
        case .fetchMissing(let base):
            title = "Fetch \(base)"
            directory = path
        }
        perform(title, in: directory) { [updateBaseBranch] in
            try await updateBaseBranch.execute(plan, remote: remote, checkoutPath: path)
        }
    }

    func switchTo(_ branch: String, plan: SwitchBranchUseCase.Plan) {
        let path = checkoutPath
        let title = plan == .stashSwitchPop ? "Stash and switch to \(branch)" : "Switch to \(branch)"
        perform(title, in: path) { [switchBranch, activity] in
            let outcome = try await switchBranch.execute(plan, branch: branch, in: path)
            guard outcome == .switchedStashKept else { return }
            activity.log(
                "Your changes stay in the stash",
                detail: "git stash pop failed on \(branch). Solve the conflicts, then apply the newest stash.",
                outcome: .failure
            )
        }
    }

    func checkOut(_ remote: RemoteBranch) {
        let plan = CheckOutRemoteBranchUseCase.plan(remote: remote, localBranches: state?.localBranches ?? [], remoteName: self.remote)
        let title: String
        switch plan {
        case .switchExisting(let local):
            title = "Switch to \(local)"
        case .createTracking(let local, _):
            title = "Check out \(local)"
        }
        let path = checkoutPath
        perform(title, in: path) { [checkOutRemoteBranch] in
            try await checkOutRemoteBranch.execute(plan, checkoutPath: path)
        }
    }

    func delete(_ branch: GitBranch, force: Bool) {
        run(force ? "Force delete \(branch.name)" : "Delete \(branch.name)", .deleteBranch(branch.name, force: force))
    }

    func deleteBranches(_ branches: [GitBranch], forceGone: Bool) {
        guard branches.isEmpty == false, isBusy == false else { return }
        let path = checkoutPath
        bulkDelete = BulkProgress(done: 0, total: branches.count, current: branches[0].name)
        Task { [weak self] in
            guard let self else { return }
            var refused: [String] = []
            for (index, branch) in branches.enumerated() {
                bulkDelete = BulkProgress(done: index, total: branches.count, current: branch.name)
                do {
                    try await repository.perform(.deleteBranch(branch.name, force: BranchCleanupPolicy.usesForce(branch, forceGone: forceGone)), in: path)
                } catch {
                    refused.append(branch.name)
                }
            }
            bulkDelete = nil
            let deleted = branches.count - refused.count
            let title = "Deleted \(CountText.count(deleted, "branch", "branches"))" + (refused.isEmpty ? "" : ", \(refused.count) refused")
            activity.log(title, detail: refused.isEmpty ? path.abbreviatingHome : "Refused: \(refused.joined(separator: ", "))", outcome: refused.isEmpty ? .success : .failure)
            await refresh()
            postBranchesChanged()
        }
    }

    // MARK: Web

    func repositoryWebURL() async -> URL? {
        if let url = snapshot?.webURL {
            return url
        }
        return await repository.webURL(checkoutPath: checkoutPath, remote: remote)
    }

    func branchURL(_ branch: String) -> URL? {
        guard let base = snapshot?.webURL else { return nil }
        return RepositoryWebLinks.branchURL(base: base, kind: gitSettings.hostKind, branch: branch, remote: remote)
    }

    func newPullRequestURL(_ branch: String) -> URL? {
        newPullRequestURL(branch, target: baseName)
    }

    func newPullRequestURL(_ branch: String, target: String) -> URL? {
        guard let base = snapshot?.webURL else { return nil }
        return RepositoryWebLinks.newPullRequestURL(base: base, kind: gitSettings.hostKind, branch: branch, baseName: target, remote: remote)
    }

    func localBranch(named name: String) -> GitBranch? {
        state?.localBranches.first { $0.name == name }
    }

    func pullRequestTargets(for branch: String) -> [String] {
        PullRequestTargetPolicy.targets(
            remoteBranches: (state?.remoteBranches ?? []).map(\.name),
            source: branch,
            baseName: baseName,
            remote: remote,
            preferred: gitSettings.pullRequests.targets
        )
    }

    // MARK: Runner

    private func updateTitle(_ plan: UpdateBranchUseCase.Plan, branch: GitBranch) -> String {
        switch plan {
        case .pullHere:
            return "Pull \(branch.name)"
        case .pullInWorktree:
            return "Pull \(branch.name) in its worktree"
        case .fastForward:
            return "Fast-forward \(branch.name)"
        }
    }

    private func directory(for plan: UpdateBranchUseCase.Plan) -> String {
        guard case .pullInWorktree(let path) = plan else { return checkoutPath }
        return path
    }

    func run(_ title: String, _ command: GitCommand) {
        let path = checkoutPath
        perform(title, in: path) { [repository] in
            try await repository.perform(command, in: path)
        }
    }

    private func perform(_ title: String, in directory: String, _ work: @escaping () async throws -> Void) {
        guard isBusy == false else { return }
        runner.run(
            title,
            detail: directory.abbreviatingHome,
            onFailure: { [events] in events.post(.commandFailed) },
            completion: { [weak self] in
                guard let self else { return }
                await refresh()
                postBranchesChanged()
            },
            work: work
        )
    }

    private func postBranchesChanged() {
        isPostingBranchesChanged = true
        events.post(.branchesChanged)
        isPostingBranchesChanged = false
    }
}
