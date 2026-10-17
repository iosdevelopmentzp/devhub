import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct PortSpiesTests {
    @Test func useCasesBuildOverSpies() {
        let (ports, _) = Ports.spies()
        _ = UseCases(ports: ports)
    }

    @Test func scriptedFailureIsThrownAndRecorded() async {
        let (ports, spies) = Ports.spies()
        spies.git.stateResult = .failure(TestError.scripted("x"))

        await #expect(throws: TestError.scripted("x")) {
            try await ports.git.state(checkoutPath: "a", mainPath: "b", settings: .standard)
        }
        #expect(spies.git.calls == [.state(checkoutPath: "a", mainPath: "b")])
        #expect(spies.git.settings == [.standard])
    }

    @Test func spiesWorkWithoutSetup() async throws {
        let (ports, spies) = Ports.spies()

        try await ports.git.perform(.fetchPrune(remote: "origin"), in: "repo")
        let worktrees = try await ports.worktrees.list(projectPath: "repo", settings: .standard)

        #expect(worktrees.isEmpty)
        #expect(spies.git.calls == [.perform(.fetchPrune(remote: "origin"), path: "repo")])
        #expect(spies.worktrees.calls == [.list(projectPath: "repo")])
    }
}
