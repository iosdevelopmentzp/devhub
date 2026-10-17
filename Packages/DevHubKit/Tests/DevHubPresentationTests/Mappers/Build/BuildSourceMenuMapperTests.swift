import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct BuildSourceMenuMapperTests {
    @Test func iconPerSource() {
        #expect(BuildSourceMenuMapper.icon(for: .main) == "house")
        #expect(BuildSourceMenuMapper.icon(for: .worktree("/tmp/a")) == "rectangle.stack")
        #expect(BuildSourceMenuMapper.icon(for: .branch("feature/a")) == "arrow.triangle.branch")
    }

    @Test func modelListsLinkedWorktreesOnly() {
        var missing = WorktreeFixture.nested
        missing.isMissing = true
        let worktrees = [WorktreeFixture.main, WorktreeFixture.linked, missing]

        let model = BuildSourceMenuMapper.model(source: .worktree(WorktreeFixture.linked.path), label: "feature/login", worktrees: worktrees, projectName: "ExampleApp")

        #expect(model.label == "feature/login")
        #expect(model.icon == "rectangle.stack")
        #expect(model.hint == "Source: feature/login\nWhat to build: the main checkout, a worktree, or any branch. A branch without a worktree gets one on the next run.")
        #expect(model.mainTitle == "Main checkout · dev")
        #expect(model.worktreesTitle == "Worktrees")
        #expect(model.worktrees == [BuildSourceMenuModel.Item(path: WorktreeFixture.linked.path, title: "feature/login")])
        #expect(model.otherBranchTitle == "Other Branch…")
    }

    @Test func mainTitleFallsBackToProjectName() {
        let model = BuildSourceMenuMapper.model(source: .main, label: "dev", worktrees: [], projectName: "ExampleApp")

        #expect(model.mainTitle == "Main checkout · ExampleApp")
        #expect(model.icon == "house")
        #expect(model.worktrees.isEmpty)
    }

    @Test func itemIDIsThePath() {
        #expect(BuildSourceMenuModel.Item(path: "/tmp/a", title: "a").id == "/tmp/a")
    }
}
