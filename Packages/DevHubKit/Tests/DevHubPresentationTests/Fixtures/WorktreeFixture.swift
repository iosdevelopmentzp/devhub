import DevHubDomain
import Foundation

enum WorktreeFixture {
    static let mainPath = "/Users/dev/Projects/ExampleApp"

    static let main = Worktree(
        id: mainPath,
        path: mainPath,
        branch: "dev",
        head: "a1b2c3d",
        kind: .main,
        isLocked: false,
        isMissing: false,
        changedFiles: 0,
        upstream: "origin/dev",
        isUpstreamGone: false,
        ahead: 0,
        behind: 0,
        isMerged: false,
        lastCommit: "Merge branch 'feature/login'",
        lastActivity: nil,
        needsBootstrap: false
    )

    static let linked = Worktree(
        id: "/Users/dev/Projects/ExampleApp-login",
        path: "/Users/dev/Projects/ExampleApp-login",
        branch: "feature/login",
        head: "b2c3d4e",
        kind: .linked,
        isLocked: false,
        isMissing: false,
        changedFiles: 0,
        upstream: "origin/feature/login",
        isUpstreamGone: false,
        ahead: 0,
        behind: 0,
        isMerged: false,
        lastCommit: "ABC-1: Login screen",
        lastActivity: Date(timeIntervalSince1970: 1_000_000),
        needsBootstrap: false
    )

    static let agent = Worktree(
        id: "\(mainPath)/.claude/worktrees/gifts",
        path: "\(mainPath)/.claude/worktrees/gifts",
        branch: "feature/gifts",
        head: "c3d4e5f",
        kind: .agent,
        isLocked: false,
        isMissing: false,
        changedFiles: 0,
        upstream: "origin/feature/gifts",
        isUpstreamGone: false,
        ahead: 0,
        behind: 0,
        isMerged: false,
        lastCommit: "",
        lastActivity: Date(timeIntervalSince1970: 2_000_000),
        needsBootstrap: false
    )
}
