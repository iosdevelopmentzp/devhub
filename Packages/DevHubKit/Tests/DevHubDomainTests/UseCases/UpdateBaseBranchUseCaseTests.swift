import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct UpdateBaseBranchUseCaseTests {
    @Test func missingBaseBranchIsFetched() {
        let plan = UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [GitBranchFixture.local("feature")], currentBranch: "feature", remote: "origin")

        #expect(plan == .fetchMissing("dev"))
    }

    @Test func localBaseBranchIsUpdatedWithTheBranchPlan() {
        let dev = GitBranchFixture.local("dev")

        let plan = UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [GitBranchFixture.local("feature"), dev], currentBranch: "feature", remote: "origin")

        #expect(plan == .updateLocal(dev, .fastForward(remote: "dev")))
    }

    @Test func currentBaseBranchIsPulledHere() {
        let dev = GitBranchFixture.local("dev")

        #expect(UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [dev], currentBranch: "dev", remote: "origin") == .updateLocal(dev, .pullHere))
    }

    @Test func fetchMissingCreatesTheLocalBranchFromTheRemote() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(.fetchMissing("dev"), remote: "origin", checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.fetchBranch(source: "dev", local: "dev", remote: "origin"), path: "/repo")])
    }

    @Test func updateLocalRunsTheBranchPlan() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(
            .updateLocal(GitBranchFixture.local("dev"), .fastForward(remote: "dev")),
            remote: "origin",
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.fetchBranch(source: "dev", local: "dev", remote: "origin"), path: "/repo")])
    }

    @Test func updateLocalInAWorktreePullsThere() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(
            .updateLocal(GitBranchFixture.local("dev"), .pullInWorktree(path: "/worktrees/dev")),
            remote: "origin",
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.pullFastForward, path: "/worktrees/dev")])
    }
}
