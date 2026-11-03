import Testing
import DevHubDomain
@testable import DevHubPresentation

@Suite struct WorktreeLocationMapperTests {
    private func model(_ location: WorktreeLocation, branch: String = "feature/ABC-123-login") -> WorktreeLocationModel {
        WorktreeLocationMapper.model(for: location, branch: branch, remote: "origin", root: "/work/app")
    }

    @Test func nextToTheProjectShowsTheSiblingAndOffersToKeepInside() {
        let model = model(.nextToProject)

        #expect(model.path == "/work/app-feature-ABC-123-login")
        #expect(model.canKeepInside)
        #expect(model.keepInsideHint.contains(".git/info/exclude"))
        #expect(model.keepInsideHint.contains("/work/app/.worktrees"))
    }

    @Test func insideTheProjectShowsTheWorktreesFolder() {
        let model = model(.insideProject)

        #expect(model.path == "/work/app/.worktrees/feature-ABC-123-login")
        #expect(model.canKeepInside == false)
        #expect(model.hint.contains(".worktrees/"))
    }

    @Test func aConfiguredFolderNamesTheConfigKey() {
        let model = model(.configured(folder: "../trees"))

        #expect(model.path == "/work/trees/feature-ABC-123-login")
        #expect(model.canKeepInside == false)
        #expect(model.hint.contains("git.worktrees.folder"))
    }

    @Test func anEmptyBranchShowsAPlaceholder() {
        #expect(model(.insideProject, branch: "  ").path == "/work/app/.worktrees/<branch>")
    }

    @Test func theRemotePrefixIsDropped() {
        #expect(model(.insideProject, branch: "origin/feature/x").path == "/work/app/.worktrees/feature-x")
    }
}
