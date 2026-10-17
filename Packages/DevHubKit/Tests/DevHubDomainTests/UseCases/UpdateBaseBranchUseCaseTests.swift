import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct UpdateBaseBranchUseCaseTests {
    @Test func missingBaseBranchIsFetched() {
        let plan = UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [GitBranchFixture.local("feature")], currentBranch: "feature")

        #expect(plan == .fetchMissing("dev"))
    }

    @Test func localBaseBranchIsUpdatedWithTheBranchPlan() {
        let dev = GitBranchFixture.local("dev")

        let plan = UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [GitBranchFixture.local("feature"), dev], currentBranch: "feature")

        #expect(plan == .updateLocal(dev, .fastForward(remote: "dev")))
    }

    @Test func currentBaseBranchIsPulledHere() {
        let dev = GitBranchFixture.local("dev")

        #expect(UpdateBaseBranchUseCase.plan(baseName: "dev", localBranches: [dev], currentBranch: "dev") == .updateLocal(dev, .pullHere))
    }

    @Test func fetchMissingCreatesTheLocalBranchFromTheRemote() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(.fetchMissing("dev"), checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.fetchBranch(remote: "dev", local: "dev"), path: "/repo")])
    }

    @Test func updateLocalRunsTheBranchPlan() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(
            .updateLocal(GitBranchFixture.local("dev"), .fastForward(remote: "dev")),
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.fetchBranch(remote: "dev", local: "dev"), path: "/repo")])
    }

    @Test func updateLocalInAWorktreePullsThere() async throws {
        let (ports, spies) = Ports.spies()

        try await UpdateBaseBranchUseCase(git: ports.git).execute(
            .updateLocal(GitBranchFixture.local("dev"), .pullInWorktree(path: "/worktrees/dev")),
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.pullFastForward, path: "/worktrees/dev")])
    }
}
