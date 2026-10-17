import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct CheckOutRemoteBranchUseCaseTests {
    @Test func existingLocalBranchIsSwitchedTo() {
        let plan = CheckOutRemoteBranchUseCase.plan(remote: GitBranchFixture.remote("origin/feature"), localBranches: [GitBranchFixture.local("feature")])

        #expect(plan == .switchExisting(local: "feature"))
    }

    @Test func missingLocalBranchIsCreatedTracking() {
        let plan = CheckOutRemoteBranchUseCase.plan(remote: GitBranchFixture.remote("origin/feature"), localBranches: [GitBranchFixture.local("dev")])

        #expect(plan == .createTracking(local: "feature", remote: "origin/feature"))
    }

    @Test func switchExistingRunsSwitch() async throws {
        let (ports, spies) = Ports.spies()

        try await CheckOutRemoteBranchUseCase(git: ports.git).execute(.switchExisting(local: "feature"), checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.switchBranch("feature"), path: "/repo")])
    }

    @Test func createTrackingRunsCreateTrackingBranch() async throws {
        let (ports, spies) = Ports.spies()

        try await CheckOutRemoteBranchUseCase(git: ports.git).execute(
            .createTracking(local: "feature", remote: "origin/feature"),
            checkoutPath: "/repo"
        )

        #expect(spies.git.calls == [.perform(.createTrackingBranch(local: "feature", remote: "origin/feature"), path: "/repo")])
    }
}
