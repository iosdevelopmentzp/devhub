import Testing
@testable import DevHubDomain

@Suite struct WorktreeTests {
    @Test func onlyTheMainKindIsMain() {
        var agent = WorktreeFixture.linked(branch: "agent")
        agent.kind = .agent

        #expect(WorktreeFixture.main.isMain)
        #expect(WorktreeFixture.linked(branch: "x").isMain == false)
        #expect(agent.isMain == false)
    }

    @Test func dirtyMeansChangedFiles() {
        var worktree = WorktreeFixture.linked(branch: "x")
        #expect(worktree.isDirty == false)

        worktree.changedFiles = 1
        #expect(worktree.isDirty)
    }

    @Test func displayNameIsTheBranch() {
        #expect(WorktreeFixture.linked(branch: "feature/login").displayName == "feature/login")
    }

    @Test func displayNameOfADetachedHeadShowsTheCommit() {
        #expect(WorktreeFixture.detached(head: "ccc3333").displayName == "detached @ ccc3333")
    }

    @Test func finishedWhenMerged() {
        #expect(WorktreeFixture.merged(branch: "x").isFinished)
    }

    @Test func finishedWhenUpstreamIsGone() {
        var worktree = WorktreeFixture.linked(branch: "x")
        worktree.isUpstreamGone = true

        #expect(worktree.isFinished)
    }

    @Test func notFinishedOtherwise() {
        #expect(WorktreeFixture.linked(branch: "x").isFinished == false)
    }
}
