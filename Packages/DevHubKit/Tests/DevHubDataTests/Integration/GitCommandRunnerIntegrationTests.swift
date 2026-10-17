import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct GitCommandRunnerIntegrationTests {
    private let repo: TemporaryGitRepository
    private let runner: GitCommandRunner

    init() async throws {
        repo = try await TemporaryGitRepository()
        runner = GitCommandRunner(shell: repo.shell)
    }

    @Test func runReturnsStdout() async throws {
        #expect(try await runner.run(["rev-parse", "--abbrev-ref", "HEAD"], in: repo.path) == "main\n")
    }

    @Test func runPassesTheEnvironment() async throws {
        #expect(try await runner.run(["var", "GIT_EDITOR"], in: repo.path, environment: ["GIT_EDITOR": "true"]) == "true\n")
    }

    @Test func runThrowsCommandErrorWithStderr() async throws {
        let error = await #expect(throws: WorktreeError.self) {
            try await runner.run(["not-a-command"], in: repo.path)
        }
        guard case .command(let message)? = error else {
            Issue.record("Expected .command, got \(String(describing: error))")
            return
        }
        #expect(message.contains("not-a-command"))
    }

    @Test func resultDoesNotThrowOnFailure() async throws {
        let result = try await runner.result(["rev-parse", "--verify", "--quiet", "refs/heads/missing"], in: repo.path)

        #expect(result.exitCode != 0)
    }
}
