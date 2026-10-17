import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct MergedBranchesQueryIntegrationTests {
    private let repo: TemporaryGitRepository
    private let query: MergedBranchesQuery

    init() async throws {
        repo = try await TemporaryGitRepository()
        query = MergedBranchesQuery(git: GitCommandRunner(shell: repo.shell))
    }

    @Test func listsBranchesMergedIntoTheBase() async {
        #expect(await query.branches(mergedInto: "main", in: repo.path) == ["main", "merged-branch", "linked"])
    }

    @Test func featureBranchIsMergedOnceMainContainsIt() async throws {
        try await repo.git("merge", "-q", "--no-edit", "feature")

        #expect(await query.branches(mergedInto: "main", in: repo.path).contains("feature"))
    }

    @Test func unknownBaseGivesNoBranches() async {
        #expect(await query.branches(mergedInto: "origin/main", in: repo.path).isEmpty)
    }
}
