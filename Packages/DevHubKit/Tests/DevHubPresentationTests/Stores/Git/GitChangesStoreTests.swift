import Foundation
import Testing
@testable import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct GitChangesStoreTests {
    private let harness = StoreHarness()
    private let failure = TestError.scripted("boom")
    private let path = ProjectSample.path

    private var store: GitChangesStore {
        harness.changes
    }

    private var changesCalls: Int {
        harness.spies.changes.calls.filter { $0 == .changes(path: path) }.count
    }

    private var performed: [SpyGitRepository.Call] {
        harness.spies.git.calls.filter { if case .perform = $0 { true } else { false } }
    }

    private func load(_ changes: [GitFileChange]) async {
        harness.spies.changes.changesResult = .success(changes)
        await store.refresh()
    }

    private func loadBranch() async {
        harness.spies.git.stateResult = .success(GitStateSample.state)
        await harness.git.refresh()
    }

    private func finish(_ action: () -> Void) async throws {
        let posted = harness.postCount("branchesChanged")
        action()
        try await waitUntil { harness.postCount("branchesChanged") == posted + 1 }
    }

    // MARK: Refresh

    @Test func refreshLoadsTheChanges() async {
        await load([GitFileChangeSample.staged, GitFileChangeSample.untracked])

        #expect(store.changes == [GitFileChangeSample.staged, GitFileChangeSample.untracked])
        #expect(store.loadedPath == path)
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(harness.spies.changes.calls == [.changes(path: path)])
    }

    @Test func aRefreshWithTheSameChangesDoesNotNotifyViews() async {
        await load([GitFileChangeSample.staged])
        let probe = ObservationProbe { _ = (store.changes, store.diffs, store.loadedPath, store.expandedIDs) }

        await load([GitFileChangeSample.staged])

        #expect(probe.changed == false)
    }

    @Test func aFailedRefreshSetsTheError() async {
        harness.spies.changes.changesResult = .failure(failure)

        await store.refresh()

        #expect(store.error == failure.localizedDescription)
        #expect(store.loadedPath == nil)
    }

    @Test func refreshPrunesExpandedIDsAndReloadsTheirDiffs() async {
        harness.spies.changes.diffResult = .success(GitFileChangeSample.diff)
        await load([GitFileChangeSample.staged, GitFileChangeSample.unstaged])
        store.expandedIDs = [GitFileChangeSample.staged.id, GitFileChangeSample.untracked.id]

        await load([GitFileChangeSample.staged, GitFileChangeSample.unstaged])

        #expect(store.expandedIDs == [GitFileChangeSample.staged.id])
        #expect(store.diffs == [GitFileChangeSample.staged.id: GitFileChangeSample.diff])
        #expect(harness.spies.changes.calls.last == .diff(GitFileChangeSample.staged, path: path))
    }

    @Test func refreshResetsExpandedIDsWhenThePathChanged() async {
        store.expandedIDs = [GitFileChangeSample.staged.id]

        await load([GitFileChangeSample.staged])

        #expect(store.expandedIDs.isEmpty)
        #expect(store.diffs.isEmpty)
    }

    @Test func refreshFillsAnEmptyMessageWithTheTicketPrefix() async {
        await loadBranch()

        await load([])

        #expect(store.message == "APP-12: ")
    }

    @Test func theConfiguredFormatShapesThePrefix() async {
        harness.spies.config.loadResult = ResolvedConfig(project: ProjectConfig(git: GitConfig(commitPrefix: CommitPrefixConfig(format: "[$1] "))), actions: [], tabs: [], issues: [], layers: [])
        await harness.config.reload()
        await loadBranch()

        await load([])

        #expect(store.message == "[APP-12] ")
    }

    @Test func refreshKeepsATypedMessage() async {
        await loadBranch()
        store.message = "Typed"

        await load([])

        #expect(store.message == "Typed")
    }

    // MARK: Areas

    @Test func areasSplitTheChanges() async {
        await load([
            GitFileChangeSample.staged,
            GitFileChangeSample.unstagedSamePath,
            GitFileChangeSample.untracked,
            GitFileChangeSample.conflicted,
        ])

        #expect(store.staged == [GitFileChangeSample.staged])
        #expect(store.unstaged == [GitFileChangeSample.unstagedSamePath])
        #expect(store.untracked == [GitFileChangeSample.untracked])
        #expect(store.conflicted == [GitFileChangeSample.conflicted])
        #expect(store.fileCount == 3)
    }

    // MARK: Can commit

    @Test func canCommitNeedsAMessageAndStagedFiles() async {
        await load([GitFileChangeSample.staged])
        store.message = "Fix"
        #expect(store.canCommit)

        store.message = "   "
        #expect(store.canCommit == false)
    }

    @Test func canCommitWithoutStagedFilesOnlyWhenAmending() async {
        await load([GitFileChangeSample.unstaged])
        store.message = "Fix"
        #expect(store.canCommit == false)

        store.amend = true
        #expect(store.canCommit)
    }

    @Test func canCommitIsFalseWithConflicts() async {
        await load([GitFileChangeSample.staged, GitFileChangeSample.conflicted])
        store.message = "Fix"

        #expect(store.canCommit == false)
    }

    @Test func canCommitIsFalseWhileBusy() async {
        await load([GitFileChangeSample.staged])
        store.message = "Fix"

        store.stageAll()

        #expect(store.busyTitle == "Stage all")
        #expect(store.canCommit == false)
    }

    // MARK: Diff

    @Test func toggleDiffLoadsTheDiffAndCollapses() async throws {
        harness.spies.changes.diffResult = .success(GitFileChangeSample.diff)

        store.toggleDiff(GitFileChangeSample.unstaged)

        #expect(store.expandedIDs == [GitFileChangeSample.unstaged.id])
        try await waitUntil { store.diffs[GitFileChangeSample.unstaged.id] == GitFileChangeSample.diff }
        #expect(harness.spies.changes.calls == [.diff(GitFileChangeSample.unstaged, path: path)])

        store.toggleDiff(GitFileChangeSample.unstaged)

        #expect(store.expandedIDs.isEmpty)
    }

    @Test func aFailedDiffShowsTheErrorAsALine() async throws {
        harness.spies.changes.diffResult = .failure(failure)

        store.toggleDiff(GitFileChangeSample.unstaged)

        try await waitUntil { store.diffs[GitFileChangeSample.unstaged.id] != nil }
        #expect(store.diffs[GitFileChangeSample.unstaged.id]?.lines == [failure.localizedDescription])
    }

    // MARK: Index

    @Test func stageStagesThePath() async throws {
        try await finish { store.stage(GitFileChangeSample.unstaged) }

        #expect(performed == [.perform(.stage(path: "Sources/B.swift"), path: path)])
        #expect(harness.lastActivity?.title == "Stage B.swift")
    }

    @Test func unstageUnstagesThePath() async throws {
        try await finish { store.unstage(GitFileChangeSample.staged) }

        #expect(performed == [.perform(.unstage(path: "Sources/A.swift"), path: path)])
        #expect(harness.lastActivity?.title == "Unstage A.swift")
    }

    @Test func stageAllAndUnstageAll() async throws {
        try await finish { store.stageAll() }
        try await finish { store.unstageAll() }

        #expect(performed == [.perform(.stageAll, path: path), .perform(.unstageAll, path: path)])
    }

    @Test func discardAnUntrackedFileDeletesIt() async throws {
        try await finish { store.discard(GitFileChangeSample.untracked) }

        #expect(performed == [.perform(.cleanUntracked(path: "notes.txt"), path: path)])
        #expect(harness.lastActivity?.title == "Delete notes.txt")
    }

    @Test func discardAnUnstagedFileRestoresIt() async throws {
        try await finish { store.discard(GitFileChangeSample.unstaged) }

        #expect(performed == [.perform(.restore(path: "Sources/B.swift"), path: path)])
        #expect(harness.lastActivity?.title == "Discard changes in B.swift")
    }

    @Test func discardAStagedFileRestoresTheIndexAndTheWorktree() async throws {
        try await finish { store.discard(GitFileChangeSample.staged) }

        #expect(performed == [.perform(.restoreStagedAndWorktree(path: "Sources/A.swift"), path: path)])
    }

    @Test func aFailedIndexCommandLogsAndPostsCommandFailed() async throws {
        harness.spies.git.performError = failure

        try await finish { store.stage(GitFileChangeSample.unstaged) }

        #expect(harness.lastActivity?.title == "Stage B.swift failed")
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postedLabels == ["commandFailed", "branchesChanged"])
    }

    @Test func aLoadedStoreRefreshesAfterItsOwnBranchesChanged() async throws {
        await load([GitFileChangeSample.unstaged])

        try await finish { store.stage(GitFileChangeSample.unstaged) }

        try await waitUntil { changesCalls == 2 }
    }

    // MARK: Commit

    @Test func commitResetsTheMessageAndAmend() async throws {
        await loadBranch()
        await load([GitFileChangeSample.staged])
        store.message = "APP-12: Fix login "

        try await finish { store.commit(thenPush: false) }

        #expect(performed == [.perform(.commit(message: "APP-12: Fix login", amend: false), path: path)])
        #expect(store.message == "APP-12: ")
        #expect(store.amend == false)
        #expect(harness.lastActivity?.title == "Commit")
    }

    @Test func amendCommitsWithoutStagedFiles() async throws {
        await load([])
        store.message = "Fix"
        store.amend = true

        try await finish { store.commit(thenPush: false) }

        #expect(performed == [.perform(.commit(message: "Fix", amend: true), path: path)])
        #expect(store.amend == false)
        #expect(harness.lastActivity?.title == "Amend commit")
    }

    @Test func commitThenPushLogsThePush() async throws {
        await loadBranch()
        await load([GitFileChangeSample.staged])
        store.message = "APP-12: Fix"

        try await finish { store.commit(thenPush: true) }

        #expect(performed == [
            .perform(.commit(message: "APP-12: Fix", amend: false), path: path),
            .perform(.push(branch: "APP-12-login", setUpstream: false, remote: "origin"), path: path),
        ])
        #expect(Array(harness.activityTitles.prefix(2)) == ["Push APP-12-login", "Commit"])
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aFailedPushLogsAFailureAndPostsCommandFailed() async throws {
        await loadBranch()
        let store = GitChangesStore(
            repository: harness.ports.changes,
            git: harness.ports.git,
            discardChange: harness.useCases.discardChange,
            commitChanges: CommitUseCase(git: PushRejectingGitRepository()),
            checkout: harness.git,
            activity: harness.activity,
            events: harness.events
        )
        harness.spies.changes.changesResult = .success([GitFileChangeSample.staged])
        await store.refresh()
        store.message = "APP-12: Fix"

        try await finish { store.commit(thenPush: true) }

        #expect(Array(harness.activityTitles.prefix(2)) == ["Push APP-12-login failed", "Commit"])
        #expect(harness.lastActivity?.outcome == .failure)
        #expect(harness.postedLabels.suffix(2) == ["commandFailed", "branchesChanged"])
        #expect(store.message == "APP-12: ")
    }

    @Test func aFailedCommitKeepsTheMessage() async throws {
        await load([GitFileChangeSample.staged])
        store.message = "Fix"
        harness.spies.git.performError = failure

        try await finish { store.commit(thenPush: false) }

        #expect(store.message == "Fix")
        #expect(harness.lastActivity?.title == "Commit failed")
        #expect(harness.postedLabels == ["commandFailed", "branchesChanged"])
    }

    @Test func commitDoesNothingWhenItCannotCommit() {
        store.commit(thenPush: false)

        #expect(store.busyTitle == nil)
    }

    // MARK: Events

    @Test func branchesChangedRefreshesALoadedStore() async throws {
        await load([])

        harness.events.post(.branchesChanged)

        try await waitUntil { changesCalls == 2 }
    }

    @Test func branchesChangedIsIgnoredBeforeTheFirstLoad() async {
        _ = store
        harness.events.post(.branchesChanged)
        await harness.settle()

        #expect(changesCalls == 0)
    }

    @Test func projectChangedClearsTheChanges() async throws {
        harness.spies.changes.diffResult = .success(GitFileChangeSample.diff)
        await load([GitFileChangeSample.staged])
        store.toggleDiff(GitFileChangeSample.staged)
        try await waitUntil { store.diffs.isEmpty == false }

        harness.events.post(.projectChanged)

        #expect(store.changes.isEmpty)
        #expect(store.diffs.isEmpty)
        #expect(store.loadedPath == nil)
    }
}

private nonisolated final class PushRejectingGitRepository: GitRepository {
    func state(checkoutPath: String, mainPath: String, settings: GitSettings) async throws -> GitRepositoryState {
        throw TestError.scripted("unused")
    }

    func perform(_ command: GitCommand, in path: String) async throws {
        guard case .push = command else { return }
        throw TestError.scripted("rejected")
    }

    func webURL(checkoutPath: String, remote: String) async -> URL? {
        nil
    }

    func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String] {
        []
    }

    func pullRequestTemplate(in path: String, file: String) async -> String? {
        nil
    }
}
