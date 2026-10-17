import Foundation
import DevHubDomain

enum GitStateSample {
    static let webURL = URL(string: "https://gitlab.example.com/team/app")!
    static let linkedPath = "/tmp/DevHubTests/App-linked"

    static let current = branch("APP-12-login", worktreePath: nil)
    static let dev = branch("dev", worktreePath: nil)
    static let linked = branch("feature/linked", worktreePath: linkedPath)

    static let remoteDev = RemoteBranch(name: "origin/dev", author: "Dev", subject: "Base", commitDate: nil)
    static let remoteNew = RemoteBranch(name: "origin/feature/new", author: "Dev", subject: "New", commitDate: nil)

    static let snapshot = GitSnapshot(
        branch: current.name,
        head: "abc1234",
        upstream: "origin/\(current.name)",
        ahead: 1,
        behind: 0,
        changedFiles: 0,
        stashCount: 1,
        operation: nil,
        baseBranch: "origin/dev",
        aheadOfBase: 2,
        behindBase: 0,
        lastFetch: nil,
        webURL: webURL
    )

    static let state = GitRepositoryState(
        snapshot: snapshot,
        localBranches: [dev, current, linked],
        remoteBranches: [remoteDev, remoteNew],
        history: []
    )

    static let withoutUpstream: GitRepositoryState = {
        var value = state
        value.snapshot.upstream = nil
        return value
    }()

    static let rebasing: GitRepositoryState = {
        var value = state
        value.snapshot.operation = "rebase"
        return value
    }()

    static let withoutBaseBranch: GitRepositoryState = {
        var value = state
        value.localBranches = [current, linked]
        return value
    }()

    static let otherBranch: GitRepositoryState = {
        var value = state
        value.snapshot.branch = "APP-99-other"
        return value
    }()

    static func branch(_ name: String, worktreePath: String?) -> GitBranch {
        GitBranch(
            name: name,
            upstream: "origin/\(name)",
            ahead: 0,
            behind: 0,
            isGone: false,
            isMerged: false,
            subject: "Subject",
            commitDate: nil,
            lastVisited: nil,
            worktreePath: worktreePath
        )
    }
}
