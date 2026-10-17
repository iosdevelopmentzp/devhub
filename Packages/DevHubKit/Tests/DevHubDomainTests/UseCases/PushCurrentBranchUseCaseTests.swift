import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct PushCurrentBranchUseCaseTests {
    @Test func setsUpstreamWhenThereIsNone() async throws {
        let (ports, spies) = Ports.spies()

        try await PushCurrentBranchUseCase(git: ports.git).execute(branch: "feature", upstream: nil, checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.push(branch: "feature", setUpstream: true), path: "/repo")])
    }

    @Test func plainPushWhenUpstreamExists() async throws {
        let (ports, spies) = Ports.spies()

        try await PushCurrentBranchUseCase(git: ports.git).execute(branch: "feature", upstream: "origin/feature", checkoutPath: "/repo")

        #expect(spies.git.calls == [.perform(.push(branch: "feature", setUpstream: false), path: "/repo")])
    }
}
