import Testing
@testable import DevHubDomain

@Suite struct WorktreeCleanupPolicyTests {
    @Test func mergedCleanLinkedWorktreeIsSafe() {
        #expect(WorktreeCleanupPolicy.isSafeToClean(WorktreeFixture.merged(branch: "done")))
    }

    @Test func worktreeWithGoneUpstreamIsSafe() {
        var worktree = WorktreeFixture.linked(branch: "done")
        worktree.isUpstreamGone = true

        #expect(WorktreeCleanupPolicy.isSafeToClean(worktree))
    }

    @Test func mainWorktreeIsNeverSafe() {
        var main = WorktreeFixture.main
        main.isMerged = true

        #expect(WorktreeCleanupPolicy.isSafeToClean(main) == false)
    }

    @Test func unfinishedWorktreeIsNotSafe() {
        #expect(WorktreeCleanupPolicy.isSafeToClean(WorktreeFixture.linked(branch: "wip")) == false)
    }

    @Test func dirtyWorktreeIsNotSafe() {
        var worktree = WorktreeFixture.merged(branch: "done")
        worktree.changedFiles = 1

        #expect(WorktreeCleanupPolicy.isSafeToClean(worktree) == false)
    }

    @Test func lockedWorktreeIsNotSafe() {
        var worktree = WorktreeFixture.merged(branch: "done")
        worktree.isLocked = true

        #expect(WorktreeCleanupPolicy.isSafeToClean(worktree) == false)
    }

    @Test func missingWorktreeIsNotSafe() {
        var worktree = WorktreeFixture.merged(branch: "done")
        worktree.isMissing = true

        #expect(WorktreeCleanupPolicy.isSafeToClean(worktree) == false)
    }

    @Test func finishedKeepsSafeWorktreesExceptTheExcludedPath() {
        let first = WorktreeFixture.merged(branch: "first")
        let second = WorktreeFixture.merged(branch: "second")
        let worktrees = [WorktreeFixture.main, first, WorktreeFixture.linked(branch: "wip"), second]

        #expect(WorktreeCleanupPolicy.finished(in: worktrees, excluding: second.path) == [first])
        #expect(WorktreeCleanupPolicy.finished(in: worktrees, excluding: nil) == [first, second])
    }

    @Test func cleanPushedWorktreeHasNoWarnings() {
        #expect(WorktreeCleanupPolicy.deleteWarnings(for: WorktreeFixture.linked(branch: "wip")).isEmpty)
    }

    @Test func dirtyUnpushedLockedWorktreeListsEveryWarningInOrder() {
        var worktree = WorktreeFixture.linked(branch: "wip")
        worktree.changedFiles = 3
        worktree.upstream = nil
        worktree.isLocked = true

        #expect(WorktreeCleanupPolicy.deleteWarnings(for: worktree) == [
            "3 uncommitted changes will be lost (git worktree remove --force).",
            "The branch was never pushed. Keep the branch to keep its commits.",
            "The worktree is locked.",
        ])
    }

    @Test func commitsAheadAreReported() {
        var worktree = WorktreeFixture.linked(branch: "wip")
        worktree.ahead = 2

        #expect(WorktreeCleanupPolicy.deleteWarnings(for: worktree) == ["2 commits are not pushed. Keep the branch to keep them."])
    }

    @Test func finishedBranchWithoutUpstreamIsNotCalledUnpushed() {
        var worktree = WorktreeFixture.merged(branch: "done")
        worktree.upstream = nil

        #expect(WorktreeCleanupPolicy.deleteWarnings(for: worktree).isEmpty)
    }

    @Test func detachedWorktreeOnlyReportsCommitsAhead() {
        var worktree = WorktreeFixture.detached(head: "ccc3333")
        worktree.ahead = 1

        #expect(WorktreeCleanupPolicy.deleteWarnings(for: worktree) == ["1 commits are not pushed. Keep the branch to keep them."])
    }

    @Test func branchIsDeletedByDefaultOnlyWhenFinished() {
        #expect(WorktreeCleanupPolicy.defaultDeleteBranch(for: WorktreeFixture.merged(branch: "done")))
        #expect(WorktreeCleanupPolicy.defaultDeleteBranch(for: WorktreeFixture.linked(branch: "wip")) == false)
    }
}
