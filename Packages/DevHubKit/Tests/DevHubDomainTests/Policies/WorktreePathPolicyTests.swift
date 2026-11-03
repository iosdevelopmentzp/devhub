import Foundation
import Testing
@testable import DevHubDomain

@Suite struct WorktreePathPolicyTests {
    @Test func withoutAFolderTheWorktreeIsASibling() {
        #expect(WorktreePathPolicy.path(forBranch: "feature/ABC-123-login", root: "/work/app", folder: nil) == "/work/app-feature-ABC-123-login")
    }

    @Test func aRelativeFolderIsUnderTheRepository() {
        #expect(WorktreePathPolicy.path(forBranch: "feature/x", root: "/work/app", folder: ".worktrees") == "/work/app/.worktrees/feature-x")
        #expect(WorktreePathPolicy.path(forBranch: "main", root: "/work/app", folder: "../trees") == "/work/trees/main")
    }

    @Test func anAbsoluteFolderIsUsedAsIs() {
        #expect(WorktreePathPolicy.path(forBranch: "fix", root: "/work/app", folder: "/tmp/trees") == "/tmp/trees/fix")
    }

    // MARK: Location

    @Test func theLocationGivesTheFolder() {
        #expect(WorktreePathPolicy.folder(for: .configured(folder: "../trees")) == "../trees")
        #expect(WorktreePathPolicy.folder(for: .insideProject) == ".worktrees")
        #expect(WorktreePathPolicy.folder(for: .nextToProject) == nil)
    }

    // MARK: Exclude

    @Test func anEmptyExcludeGetsTheHeaderAndThePattern() {
        #expect(WorktreePathPolicy.exclude(addingProjectFolderTo: "") == "# Worktrees created by DevHub\n.worktrees/\n")
    }

    @Test func theLinesAreAddedAfterTheExistingText() {
        #expect(WorktreePathPolicy.exclude(addingProjectFolderTo: "*.log\n") == "*.log\n# Worktrees created by DevHub\n.worktrees/\n")
    }

    @Test func aLastLineWithoutANewlineIsClosedFirst() {
        #expect(WorktreePathPolicy.exclude(addingProjectFolderTo: "*.log") == "*.log\n# Worktrees created by DevHub\n.worktrees/\n")
    }

    @Test(arguments: [".worktrees", ".worktrees/", "/.worktrees", "/.worktrees/", "  .worktrees/  "])
    func anExistingPatternIsNotAddedAgain(line: String) {
        #expect(WorktreePathPolicy.exclude(addingProjectFolderTo: "*.log\n\(line)\n") == nil)
    }

    @Test func anotherFolderWithTheSameStartDoesNotCount() {
        #expect(WorktreePathPolicy.exclude(addingProjectFolderTo: ".worktrees-old/\n") != nil)
    }
}
