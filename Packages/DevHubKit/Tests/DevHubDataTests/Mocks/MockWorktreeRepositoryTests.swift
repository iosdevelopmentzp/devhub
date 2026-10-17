import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockWorktreeRepositoryTests {
    private let repository = MockWorktreeRepository()

    @Test func answersCannedData() async throws {
        #expect(try await repository.list(projectPath: "~/App") == MockData.worktrees)
        #expect(await repository.baseBranch(projectPath: "~/App") == "origin/dev")
        try await repository.deleteBranch("old", projectPath: "~/App")
        try await repository.prune(projectPath: "~/App")
    }
}
