import DevHubTestSupport
import Testing
@testable import DevHubDomain

@Suite struct CreateWorktreeUseCaseTests {
    @Test(arguments: ["", "   ", "origin/"])
    func emptyNameCreatesNothing(branch: String) async throws {
        let (ports, spies) = Ports.spies()

        let created = try await CreateWorktreeUseCase(worktrees: ports.worktrees).execute(branch: branch, base: "origin/dev", projectPath: "/repo", settings: .standard)

        #expect(created == nil)
        #expect(spies.worktrees.calls.isEmpty)
    }

    @Test func remoteBranchIsCreatedUnderItsLocalName() async throws {
        let (ports, spies) = Ports.spies()

        _ = try await CreateWorktreeUseCase(worktrees: ports.worktrees).execute(branch: " origin/feature \n", base: "origin/dev", projectPath: "/repo", settings: .standard)

        #expect(spies.worktrees.calls == [.create(branch: "feature", base: "origin/dev", projectPath: "/repo")])
        #expect(spies.worktrees.settings == [.standard])
    }

    @Test func returnsTheCreatedWorktree() async throws {
        let (ports, spies) = Ports.spies()
        spies.worktrees.createResult = .success(NewWorktree(path: "/worktrees/feature", branch: "feature"))

        let created = try await CreateWorktreeUseCase(worktrees: ports.worktrees).execute(branch: "feature", base: "origin/dev", projectPath: "/repo", settings: .standard)

        #expect(created?.path == "/worktrees/feature")
        #expect(created?.branch == "feature")
    }

    @Test func creationFailureIsThrown() async {
        let (ports, spies) = Ports.spies()
        spies.worktrees.createResult = .failure(TestError.scripted("already exists"))

        await #expect(throws: TestError.scripted("already exists")) {
            try await CreateWorktreeUseCase(worktrees: ports.worktrees).execute(branch: "feature", base: "origin/dev", projectPath: "/repo", settings: .standard)
        }
    }
}
