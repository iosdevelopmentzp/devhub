import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct UpdateBranchUseCaseTests {
    @Test func pullsHereWhenTheBranchIsCurrent() {
        var branch = GitBranchFixture.local("feature")
        branch.worktreePath = "/worktrees/feature"

        #expect(UpdateBranchUseCase.plan(branch: branch, currentBranch: "feature", remote: "origin") == .pullHere)
    }

    @Test func pullsInTheWorktreeThatHasTheBranch() {
        var branch = GitBranchFixture.local("feature")
        branch.worktreePath = "/worktrees/feature"

        #expect(UpdateBranchUseCase.plan(branch: branch, currentBranch: "dev", remote: "origin") == .pullInWorktree(path: "/worktrees/feature"))
    }

    @Test func fastForwardsFromTheUpstreamName() {
        var branch = GitBranchFixture.local("feature")
        branch.upstream = "origin/feature-renamed"

        #expect(UpdateBranchUseCase.plan(branch: branch, currentBranch: "dev", remote: "origin") == .fastForward(remote: "feature-renamed"))
    }

    @Test func fastForwardsFromTheSameNameWithoutUpstream() {
        var branch = GitBranchFixture.local("feature")
        branch.upstream = nil

        #expect(UpdateBranchUseCase.plan(branch: branch, currentBranch: nil, remote: "origin") == .fastForward(remote: "feature"))
    }

    @Test func pullHereRunsAFastForwardPullInTheCheckout() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBranchUseCase(git: ports.git).execute(.pullHere, branch: GitBranchFixture.local("dev"), remote: "origin", checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.pullFastForward, path: "/repo")])
    }

    @Test func pullInWorktreeRunsThePullInThatWorktree() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBranchUseCase(git: ports.git).execute(
            .pullInWorktree(path: "/worktrees/feature"),
            branch: GitBranchFixture.local("feature"),
            remote: "origin",
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.pullFastForward, path: "/worktrees/feature")])
    }

    @Test func fastForwardFetchesTheRemoteIntoTheLocalBranch() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBranchUseCase(git: ports.git).execute(
            .fastForward(remote: "feature-renamed"),
            branch: GitBranchFixture.local("feature"),
            remote: "origin",
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.fetchBranch(source: "feature-renamed", local: "feature", remote: "origin"), path: "/repo")])
    }

    @Test func gitFailureIsThrown() async {
        let (ports, spies) = Ports.spies()
        spies.git.performError = TestError.scripted("not a fast-forward")

        await #expect(throws: TestError.scripted("not a fast-forward")) {
            try await UpdateBranchUseCase(git: ports.git).execute(.pullHere, branch: GitBranchFixture.local("dev"), remote: "origin", checkoutPath: "/repo")
        }
    }
}
