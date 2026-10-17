import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct GitStoreTests {
    private let harness = StoreHarness()
    private let failure = TestError.scripted("boom")
    private let path = ProjectSample.path

    private var store: GitStore {
        harness.git
    }

    private var stateCalls: Int {
        harness.spies.git.calls.filter { if case .state = $0 { true } else { false } }.count
    }

    private var performed: [SpyGitRepository.Call] {
        harness.spies.git.calls.filter { if case .perform = $0 { true } else { false } }
    }

    private func load(_ state: GitRepositoryState) async {
        harness.spies.git.stateResult = .success(state)
        await store.refresh()
    }

    private func finish(_ action: () -> Void) async throws {
        let posted = harness.postCount("branchesChanged")
        action()
        try await waitUntil { harness.postCount("branchesChanged") == posted + 1 }
    }

    // MARK: Bulk delete

    @Test func mergedSectionStartsCollapsedAndRemembersTheChoice() {
        #expect(store.isMergedCollapsed)

        store.isMergedCollapsed = false

        #expect(harness.store.decode(Bool.self, forKey: "git.mergedCollapsed") == false)
    }

    @Test func bulkDeleteContinuesAfterARefusalAndLogsOneLine() async throws {
        await load(GitStateSample.state)
        var merged = GitBranchFixture.feature
        merged.name = "merged"
        merged.isMerged = true
        var gone = GitBranchFixture.feature
        gone.name = "gone"
        gone.isGone = true
        var refused = GitBranchFixture.feature
        refused.name = "refused"
        refused.isMerged = true
        harness.spies.git.commandErrors = [.deleteBranch("refused", force: false): failure]

        try await finish { store.deleteBranches([merged, refused, gone], forceGone: true) }

        #expect(performed == [
            .perform(.deleteBranch("merged", force: false), path: path),
            .perform(.deleteBranch("refused", force: false), path: path),
            .perform(.deleteBranch("gone", force: true), path: path),
        ])
        #expect(store.bulkDelete == nil)
        #expect(harness.lastActivity?.title == "Deleted 2 branches, 1 refused")
        #expect(harness.lastActivity?.detail == "Refused: refused")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func bulkDeleteWithoutForceKeepsDashD() async throws {
        await load(GitStateSample.state)
        var gone = GitBranchFixture.feature
        gone.name = "gone"
        gone.isGone = true

        try await finish { store.deleteBranches([gone], forceGone: false) }

        #expect(performed == [.perform(.deleteBranch("gone", force: false), path: path)])
        #expect(harness.lastActivity?.title == "Deleted 1 branch")
        #expect(harness.lastActivity?.outcome == .success)
    }

    // MARK: Section

    @Test func sectionDefaultsToLocal() {
        #expect(store.section == .local)
    }

    @Test func sectionIsRestoredFromTheStore() {
        let saved = InMemoryKeyValueStore()
        saved.set("History", forKey: "git.section")

        #expect(StoreHarness(store: saved).git.section == .history)
    }

    @Test func sectionIsWrittenOnChange() {
        store.section = .remote

        #expect(harness.store.string(forKey: "git.section") == "Remote")
    }

    // MARK: Refresh

    @Test func refreshSetsTheState() async {
        await load(GitStateSample.state)

        #expect(store.state == GitStateSample.state)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(harness.spies.git.calls == [.state(checkoutPath: path, mainPath: path)])
    }

    @Test func aRefreshWithTheSameStateDoesNotNotifyViews() async {
        await load(GitStateSample.state)
        let probe = ObservationProbe { _ = store.state }

        await load(GitStateSample.state)

        #expect(probe.changed == false)
    }

    @Test func aFailedRefreshSetsTheErrorAndKeepsTheState() async {
        await load(GitStateSample.state)
        harness.spies.git.stateResult = .failure(failure)

        await store.refresh()

        #expect(store.error == failure.localizedDescription)
        #expect(store.state == GitStateSample.state)
    }

    @Test func selectCheckoutResetsTheStateAndRefreshesThatCheckout() async throws {
        await load(GitStateSample.state)

        store.selectCheckout(WorktreeSample.feature.path)

        #expect(store.state == nil)
        #expect(store.checkoutPath == WorktreeSample.feature.path)
        try await waitUntil { store.state != nil }
        #expect(harness.spies.git.calls.last == .state(checkoutPath: WorktreeSample.feature.path, mainPath: path))
    }

    @Test func selectingTheMainCheckoutClearsTheSelection() {
        store.selectCheckout(path)

        #expect(store.selectedCheckoutPath == nil)
        #expect(store.checkoutPath == path)
    }

    // MARK: Events

    @Test func worktreesChangedRefreshesALoadedStore() async throws {
        await load(GitStateSample.state)

        harness.events.post(.worktreesChanged)

        try await waitUntil { stateCalls == 2 }
    }

    @Test func worktreesChangedIsIgnoredBeforeTheFirstLoad() async {
        _ = store
        harness.events.post(.worktreesChanged)
        await harness.settle()

        #expect(stateCalls == 0)
    }

    @Test func worktreesChangedIsIgnoredWhileBusy() async throws {
        await load(GitStateSample.state)

        try await finish {
            store.fetch()
            harness.events.post(.worktreesChanged)
        }

        #expect(stateCalls == 2)
    }

    @Test func branchesChangedFromAnotherStoreRefreshes() async throws {
        await load(GitStateSample.state)

        harness.events.post(.branchesChanged)

        try await waitUntil { stateCalls == 2 }
    }

    @Test func projectChangedClearsTheStateAndTheSelection() async {
        await load(GitStateSample.state)
        store.selectCheckout(WorktreeSample.feature.path)

        harness.events.post(.projectChanged)

        #expect(store.state == nil)
        #expect(store.selectedCheckoutPath == nil)
    }

    // MARK: Runner

    @Test func busyTitleIsSetSynchronously() {
        store.fetch()

        #expect(store.busyTitle == "Fetch")
        #expect(store.isBusy)
    }

    @Test func anActionRefreshesAndPostsBranchesChangedOnce() async throws {
        await load(GitStateSample.state)

        try await finish { store.fetch() }
        await harness.settle()

        #expect(store.busyTitle == nil)
        #expect(stateCalls == 2)
        #expect(harness.postCount("branchesChanged") == 1)
        #expect(harness.lastActivity?.title == "Fetch")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aSecondActionWhileBusyIsIgnored() async throws {
        await load(GitStateSample.state)

        try await finish {
            store.fetch()
            store.pull()
        }

        #expect(performed == [.perform(.fetchPrune, path: path)])
    }

    @Test func aFailingCommandLogsAFailureAndPostsCommandFailed() async throws {
        await load(GitStateSample.state)
        harness.spies.git.performError = failure

        try await finish { store.pull() }

        #expect(harness.lastActivity?.title == "Pull failed")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postedLabels == ["commandFailed", "branchesChanged"])
    }

    // MARK: Commands

    @Test func fetchRunsFetchPrune() async throws {
        try await finish { store.fetch() }

        #expect(performed == [.perform(.fetchPrune, path: path)])
    }

    @Test func fetchIfStaleFetchesAnOldCheckoutOnce() async throws {
        var state = GitStateSample.state
        state.snapshot.lastFetch = Date(timeIntervalSince1970: 1_700_000_000)
        await load(state)

        try await finish { store.fetchIfStale(everyMinutes: 15, now: Date(timeIntervalSince1970: 1_700_000_000 + 20 * 60)) }

        #expect(performed == [.perform(.fetchPrune, path: path)])
    }

    @Test func fetchIfStaleSkipsAFreshCheckoutOrWhenOff() async {
        var state = GitStateSample.state
        state.snapshot.lastFetch = Date(timeIntervalSince1970: 1_700_000_000)
        await load(state)

        store.fetchIfStale(everyMinutes: 15, now: Date(timeIntervalSince1970: 1_700_000_000 + 5 * 60))
        store.fetchIfStale(everyMinutes: 0, now: Date(timeIntervalSince1970: 1_700_000_000 + 99 * 60))

        #expect(performed.isEmpty)
        #expect(store.isBusy == false)
    }

    @Test func fetchIfStaleWaitsForTheFirstRead() {
        store.fetchIfStale(everyMinutes: 15, now: .now)

        #expect(performed.isEmpty)
    }

    @Test func pullRunsAFastForwardPull() async throws {
        try await finish { store.pull() }

        #expect(performed == [.perform(.pullFastForward, path: path)])
    }

    @Test func pushWithAnUpstreamDoesNotSetIt() async throws {
        await load(GitStateSample.state)

        try await finish { store.push() }

        #expect(performed == [.perform(.push(branch: "APP-12-login", setUpstream: false), path: path)])
        #expect(harness.lastActivity?.title == "Push APP-12-login")
    }

    @Test func pushWithoutAnUpstreamSetsIt() async throws {
        await load(GitStateSample.withoutUpstream)

        try await finish { store.push() }

        #expect(performed == [.perform(.push(branch: "APP-12-login", setUpstream: true), path: path)])
    }

    @Test func pushWithoutABranchDoesNothing() {
        store.push()

        #expect(store.busyTitle == nil)
    }

    @Test func forcePushUsesLease() async throws {
        await load(GitStateSample.state)

        try await finish { store.forcePush() }

        #expect(performed == [.perform(.forcePushWithLease(branch: "APP-12-login"), path: path)])
    }

    @Test func rebaseOnBaseFetchesTheBaseThenRebases() async throws {
        await load(GitStateSample.state)

        try await finish { store.rebaseOnBase() }

        #expect(performed == [
            .perform(.fetchRef("dev"), path: path),
            .perform(.rebase(onto: "origin/dev", autostash: true), path: path),
        ])
        #expect(harness.lastActivity?.title == "Rebase on origin/dev")
    }

    @Test func continueRebaseRunsContinue() async throws {
        try await finish { store.continueRebase() }

        #expect(performed == [.perform(.continueRebase, path: path)])
    }

    @Test func abortOperationAbortsTheRunningOperation() async throws {
        await load(GitStateSample.rebasing)

        try await finish { store.abortOperation() }

        #expect(performed == [.perform(.abort(operation: "rebase"), path: path)])
        #expect(harness.lastActivity?.title == "Abort rebase")
    }

    @Test func abortOperationWithoutAnOperationDoesNothing() async {
        await load(GitStateSample.state)

        store.abortOperation()

        #expect(store.busyTitle == nil)
    }

    @Test func stashIncludesUntrackedFilesAndTheMessage() async throws {
        try await finish { store.stash(message: "half done") }

        #expect(performed == [.perform(.stashPush(message: "half done", includeUntracked: true), path: path)])
    }

    @Test func popStashPops() async throws {
        try await finish { store.popStash() }

        #expect(performed == [.perform(.stashPop(index: nil), path: path)])
    }

    @Test func stashEntriesCanBeAppliedPoppedAndDropped() async throws {
        let stash = GitStash(index: 2, branch: "dev", message: "x", date: nil)

        try await finish { store.apply(stash) }
        try await finish { store.pop(stash) }
        try await finish { store.drop(stash) }

        #expect(performed == [
            .perform(.stashApply(index: 2), path: path),
            .perform(.stashPop(index: 2), path: path),
            .perform(.stashDrop(index: 2), path: path),
        ])
        #expect(harness.lastActivity?.title == "Drop stash@{2}")
    }

    @Test func stashesComeFromTheState() async {
        var state = GitStateSample.state
        state.stashes = [GitStash(index: 0, branch: "dev", message: "x", date: nil)]

        await load(state)

        #expect(store.stashes.map(\.index) == [0])
    }

    @Test func updateTheCurrentBranchPullsHere() async throws {
        await load(GitStateSample.state)

        try await finish { store.update(GitStateSample.current) }

        #expect(performed == [.perform(.pullFastForward, path: path)])
        #expect(harness.lastActivity?.title == "Pull APP-12-login")
    }

    @Test func updateABranchWithAWorktreePullsInThatWorktree() async throws {
        await load(GitStateSample.state)

        try await finish { store.update(GitStateSample.linked) }

        #expect(performed == [.perform(.pullFastForward, path: GitStateSample.linkedPath)])
        #expect(harness.lastActivity?.title == "Pull feature/linked in its worktree")
        #expect(harness.lastActivity?.detail == GitStateSample.linkedPath)
    }

    @Test func updateAnotherBranchFastForwardsIt() async throws {
        await load(GitStateSample.state)

        try await finish { store.update(GitStateSample.dev) }

        #expect(performed == [.perform(.fetchBranch(remote: "dev", local: "dev"), path: path)])
        #expect(harness.lastActivity?.title == "Fast-forward dev")
    }

    @Test func updateBaseFastForwardsTheLocalBase() async throws {
        await load(GitStateSample.state)

        try await finish { store.updateBase() }

        #expect(performed == [.perform(.fetchBranch(remote: "dev", local: "dev"), path: path)])
        #expect(harness.lastActivity?.title == "Fast-forward dev")
    }

    @Test func updateBaseFetchesAMissingBase() async throws {
        await load(GitStateSample.withoutBaseBranch)

        try await finish { store.updateBase() }

        #expect(performed == [.perform(.fetchBranch(remote: "dev", local: "dev"), path: path)])
        #expect(harness.lastActivity?.title == "Fetch dev")
    }

    @Test func switchToSwitches() async throws {
        try await finish { store.switchTo("dev", plan: .switchOnly) }

        #expect(performed == [.perform(.switchBranch("dev"), path: path)])
        #expect(harness.lastActivity?.title == "Switch to dev")
    }

    @Test func stashAndSwitchBringsTheChangesBack() async throws {
        try await finish { store.switchTo("dev", plan: .stashSwitchPop) }

        #expect(performed == [
            .perform(.stashPush(message: "DevHub: switch to dev", includeUntracked: true), path: path),
            .perform(.switchBranch("dev"), path: path),
            .perform(.stashPop(index: nil), path: path),
        ])
        #expect(harness.lastActivity?.title == "Stash and switch to dev")
    }

    @Test func aFailedPopKeepsTheStashAndSaysSo() async throws {
        harness.spies.git.commandErrors = [.stashPop(index: nil): failure]

        try await finish { store.switchTo("dev", plan: .stashSwitchPop) }

        #expect(harness.activity.events.contains { $0.title == "Your changes stay in the stash" && $0.outcome == .failure })
        #expect(harness.lastActivity?.title == "Stash and switch to dev")
    }

    @Test func checkOutAnExistingBranchSwitches() async throws {
        await load(GitStateSample.state)

        try await finish { store.checkOut(GitStateSample.remoteDev) }

        #expect(performed == [.perform(.switchBranch("dev"), path: path)])
        #expect(harness.lastActivity?.title == "Switch to dev")
    }

    @Test func checkOutANewBranchCreatesATrackingBranch() async throws {
        await load(GitStateSample.state)

        try await finish { store.checkOut(GitStateSample.remoteNew) }

        #expect(performed == [.perform(.createTrackingBranch(local: "feature/new", remote: "origin/feature/new"), path: path)])
        #expect(harness.lastActivity?.title == "Check out feature/new")
    }

    @Test func deleteRemovesTheBranch() async throws {
        try await finish { store.delete(GitStateSample.dev, force: false) }

        #expect(performed == [.perform(.deleteBranch("dev", force: false), path: path)])
        #expect(harness.lastActivity?.title == "Delete dev")
    }

    @Test func forceDeleteForcesTheRemoval() async throws {
        try await finish { store.delete(GitStateSample.dev, force: true) }

        #expect(performed == [.perform(.deleteBranch("dev", force: true), path: path)])
        #expect(harness.lastActivity?.title == "Force delete dev")
    }

    @Test func commandsRunInTheSelectedCheckout() async throws {
        store.selectCheckout(WorktreeSample.feature.path)
        try await waitUntil { store.state != nil }

        try await finish { store.fetch() }

        #expect(performed == [.perform(.fetchPrune, path: WorktreeSample.feature.path)])
    }

    // MARK: Web

    @Test func repositoryWebURLUsesTheSnapshot() async {
        await load(GitStateSample.state)

        let url = await store.repositoryWebURL()

        #expect(url == GitStateSample.webURL)
        #expect(harness.spies.git.calls.contains(.webURL(checkoutPath: path)) == false)
    }

    @Test func repositoryWebURLAsksTheRepositoryWithoutASnapshot() async {
        let remote = URL(string: "https://github.com/team/app")!
        harness.spies.git.webURLResult = remote

        let url = await store.repositoryWebURL()

        #expect(url == remote)
        #expect(harness.spies.git.calls == [.webURL(checkoutPath: path)])
    }

    @Test func branchLinksUseTheSnapshotURL() async {
        #expect(store.branchURL("dev") == nil)
        #expect(store.newMergeRequestURL("dev") == nil)

        await load(GitStateSample.state)

        #expect(store.branchURL("origin/feature/x") == URL(string: "https://gitlab.example.com/team/app/-/tree/feature/x"))
        #expect(store.newMergeRequestURL("feature/x") == URL(string: "https://gitlab.example.com/team/app/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/x&merge_request%5Btarget_branch%5D=dev"))
    }

    @Test func mergeRequestTargetsComeFromRemoteBranches() async {
        #expect(store.mergeRequestTargets(for: "feature/x") == ["main"])

        await load(GitStateSample.state)

        #expect(store.mergeRequestTargets(for: "feature/x") == ["dev", "feature/new"])
        #expect(store.mergeRequestTargets(for: "feature/new") == ["dev"])
        #expect(store.newMergeRequestURL("feature/x", target: "feature/new") == URL(string: "https://gitlab.example.com/team/app/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature/x&merge_request%5Btarget_branch%5D=feature/new"))
    }

    // MARK: Branch lists

    @Test func branchListsAndTheCurrentBranch() async {
        await load(GitStateSample.state)

        #expect(store.localBranchNames == ["APP-12-login", "dev", "feature/linked"])
        #expect(store.currentBranch == "APP-12-login")
        #expect(store.currentUpstream == "origin/APP-12-login")
        #expect(store.webURL == GitStateSample.webURL)
    }

    @Test func baseNameComesFromTheSnapshotOrTheDefault() async {
        #expect(store.baseName == "main")

        var state = GitStateSample.state
        state.snapshot.baseBranch = "origin/main"
        await load(state)

        #expect(store.baseName == "main")
    }
}
