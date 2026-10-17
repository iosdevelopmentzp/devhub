import DevHubDomain
import Foundation

enum GitBranchFixture {
    static let feature = GitBranch(
        name: "feature/login",
        upstream: "origin/feature/login",
        ahead: 0,
        behind: 0,
        isGone: false,
        isMerged: false,
        subject: "ABC-1: Login screen",
        commitDate: nil,
        lastVisited: nil,
        worktreePath: nil
    )

    static let remote = RemoteBranch(
        name: "origin/feature/gifts",
        author: "sam",
        subject: "ABC-2: Gift animation",
        commitDate: nil
    )

    static let commit = GitCommit(
        hash: "a1b2c3d4e5f6",
        shortHash: "a1b2c3d",
        author: "alex",
        date: nil,
        subject: "ABC-1: Login screen",
        isPushed: true
    )
}
