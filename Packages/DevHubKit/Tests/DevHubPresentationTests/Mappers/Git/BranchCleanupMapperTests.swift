import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct BranchCleanupMapperTests {
    @Test func nothingToDeleteHasNoModel() {
        #expect(BranchCleanupMapper.model(for: []) == nil)
    }

    @Test func theConfirmationShowsTheCountAndFiveNames() {
        let branches = (1...7).map { branch("b\($0)") }

        let model = BranchCleanupMapper.model(for: branches)

        #expect(model == BranchCleanupModel(title: "Delete 7 merged branches?", names: "b1, b2, b3, b4, b5 and 2 more", showsForceToggle: false))
    }

    @Test func oneBranchAndTheForceToggleForGoneBranches() {
        let model = BranchCleanupMapper.model(for: [branch("old", gone: true)])

        #expect(model?.title == "Delete 1 merged branch?")
        #expect(model?.names == "old")
        #expect(model?.showsForceToggle == true)
    }

    @Test func progressCountsFromOne() {
        #expect(BranchCleanupMapper.progressText(BulkProgress(done: 11, total: 212, current: "x")) == "Deleting 12 of 212…")
    }

    private func branch(_ name: String, gone: Bool = false) -> GitBranch {
        var branch = GitBranchFixture.feature
        branch.name = name
        branch.isMerged = gone == false
        branch.isGone = gone
        return branch
    }
}
