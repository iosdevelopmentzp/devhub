@testable import DevHubDomain

enum GitBranchFixture {
    static func local(_ name: String) -> GitBranch {
        GitBranch(
            name: name,
            upstream: "origin/\(name)",
            ahead: 0,
            behind: 0,
            isGone: false,
            isMerged: false,
            subject: "Subject of \(name)",
            commitDate: nil,
            lastVisited: nil,
            worktreePath: nil
        )
    }

    static func remote(_ name: String) -> RemoteBranch {
        RemoteBranch(name: name, author: "Dev", subject: "Subject of \(name)", commitDate: nil)
    }
}
