import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockGitRepositoryTests {
    private let repository = MockGitRepository()

    @Test func answersCannedState() async throws {
        let state = try await repository.state(checkoutPath: "~/App", mainPath: "~/App")

        #expect(state.snapshot.branch == "ABC-2489-leaderboardFollowStatusReset")
        #expect(state.snapshot.baseBranch == "origin/dev")
        #expect(state.localBranches.count == 3)
        #expect(state.localBranches.first?.worktreePath == "~/App")
        #expect(state.remoteBranches.count == 2)
        #expect(state.history.count == 2)
    }

    @Test func answersWebURL() async {
        #expect(await repository.webURL(checkoutPath: "~/App") == URL(string: "https://gitlab.com/example/app"))
    }
}
