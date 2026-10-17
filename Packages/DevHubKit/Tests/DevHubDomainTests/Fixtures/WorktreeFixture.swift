@testable import DevHubDomain

enum WorktreeFixture {
    static let mainPath = "/repo"

    static let main = Worktree(
        id: mainPath,
        path: mainPath,
        branch: "dev",
        head: "aaa1111",
        kind: .main,
        isLocked: false,
        isMissing: false,
        changedFiles: 0,
        upstream: "origin/dev",
        isUpstreamGone: false,
        ahead: 0,
        behind: 0,
        isMerged: false,
        lastCommit: "Initial commit",
        lastActivity: nil,
        needsBootstrap: false
    )

    static func linked(branch: String) -> Worktree {
        linked(branch: branch, path: "/worktrees/\(branch)")
    }

    static func linked(branch: String, path: String) -> Worktree {
        Worktree(
            id: path,
            path: path,
            branch: branch,
            head: "bbb2222",
            kind: .linked,
            isLocked: false,
            isMissing: false,
            changedFiles: 0,
            upstream: "origin/\(branch)",
            isUpstreamGone: false,
            ahead: 0,
            behind: 0,
            isMerged: false,
            lastCommit: "Work in progress",
            lastActivity: nil,
            needsBootstrap: false
        )
    }

    static func merged(branch: String) -> Worktree {
        var worktree = linked(branch: branch)
        worktree.isMerged = true
        return worktree
    }

    static func detached(head: String) -> Worktree {
        var worktree = linked(branch: "detached", path: "/worktrees/detached")
        worktree.branch = nil
        worktree.upstream = nil
        worktree.head = head
        return worktree
    }
}
