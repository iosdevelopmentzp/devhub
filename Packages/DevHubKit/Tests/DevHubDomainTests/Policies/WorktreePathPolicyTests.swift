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
}
