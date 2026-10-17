import DevHubDomain

enum WorktreeSample {
    static let main: Worktree = {
        var worktree = linked(path: ProjectSample.path, branch: "dev")
        worktree.kind = .main
        return worktree
    }()

    static let feature = linked(path: "/tmp/DevHubTests/App-feature", branch: "feature/login")

    static let merged: Worktree = {
        var worktree = linked(path: "/tmp/DevHubTests/App-merged", branch: "feature/done")
        worktree.isMerged = true
        return worktree
    }()

    static let missing: Worktree = {
        var worktree = linked(path: "/tmp/DevHubTests/App-missing", branch: "feature/gone")
        worktree.isMissing = true
        return worktree
    }()

    static let needsBootstrap: Worktree = {
        var worktree = linked(path: "/tmp/DevHubTests/App-new", branch: "feature/new")
        worktree.needsBootstrap = true
        return worktree
    }()

    static let created = linked(path: "/tmp/DevHubTests/App-created", branch: "feature/created")

    static func linked(path: String, branch: String) -> Worktree {
        Worktree(
            id: path,
            path: path,
            branch: branch,
            head: "abc1234",
            kind: .linked,
            isLocked: false,
            isMissing: false,
            changedFiles: 0,
            upstream: "origin/\(branch)",
            isUpstreamGone: false,
            ahead: 0,
            behind: 0,
            isMerged: false,
            lastCommit: "Last commit",
            lastActivity: nil,
            needsBootstrap: false
        )
    }
}
