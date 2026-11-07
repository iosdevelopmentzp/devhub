import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct BuildSourceMenuMapperTests {
    @Test func modelListsLinkedWorktreesOnly() {
        var missing = WorktreeFixture.nested
        missing.isMissing = true
        let worktrees = [WorktreeFixture.main, WorktreeFixture.linked, missing]

        let model = BuildSourceMenuMapper.model(worktrees: worktrees, projectName: "ExampleApp")

        #expect(model.mainTitle == "Main checkout · dev")
        #expect(model.worktreesTitle == "Worktrees")
        #expect(model.worktrees == [BuildSourceMenuModel.Item(path: WorktreeFixture.linked.path, title: "feature/login")])
        #expect(model.otherBranchTitle == "Other Branch…")
    }

    @Test func mainTitleFallsBackToProjectName() {
        let model = BuildSourceMenuMapper.model(worktrees: [], projectName: "ExampleApp")

        #expect(model.mainTitle == "Main checkout · ExampleApp")
        #expect(model.worktrees.isEmpty)
    }

    @Test func itemIDIsThePath() {
        #expect(BuildSourceMenuModel.Item(path: "/tmp/a", title: "a").id == "/tmp/a")
    }
}
