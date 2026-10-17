import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct RebaseOnBaseUseCaseTests {
    @Test func fetchesTheBaseThenRebasesWithAutostash() async throws {
        let (ports, spies) = Ports.spies()

        try await RebaseOnBaseUseCase(git: ports.git).execute(baseName: "dev", baseRef: "origin/dev", checkoutPath: "/repo")

        #expect(spies.git.calls == [
            .perform(.fetchRef("dev"), path: "/repo"),
            .perform(.rebase(onto: "origin/dev", autostash: true), path: "/repo"),
        ])
    }

    @Test func failedFetchStopsBeforeTheRebase() async {
        let (ports, spies) = Ports.spies()
        spies.git.performError = TestError.scripted("offline")

        await #expect(throws: TestError.scripted("offline")) {
            try await RebaseOnBaseUseCase(git: ports.git).execute(baseName: "dev", baseRef: "origin/dev", checkoutPath: "/repo")
        }
        #expect(spies.git.calls == [.perform(.fetchRef("dev"), path: "/repo")])
    }
}
