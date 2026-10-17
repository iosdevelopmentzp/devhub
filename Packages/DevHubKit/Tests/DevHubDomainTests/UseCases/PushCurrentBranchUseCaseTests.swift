import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct PushCurrentBranchUseCaseTests {
    @Test func setsUpstreamWhenThereIsNone() async throws {
        let (ports, spies) = Ports.spies()

        try await PushCurrentBranchUseCase(git: ports.git).execute(branch: "feature", upstream: nil, remote: "origin", checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.push(branch: "feature", setUpstream: true, remote: "origin"), path: "/repo")])
    }

    @Test func plainPushWhenUpstreamExists() async throws {
        let (ports, spies) = Ports.spies()

        try await PushCurrentBranchUseCase(git: ports.git).execute(branch: "feature", upstream: "origin/feature", remote: "origin", checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.push(branch: "feature", setUpstream: false, remote: "origin"), path: "/repo")])
    }
}
