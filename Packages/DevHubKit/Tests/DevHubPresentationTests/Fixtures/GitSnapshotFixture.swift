import DevHubDomain
import Foundation

enum GitSnapshotFixture {
    static let clean = GitSnapshot(
        branch: "feature/login",
        head: "a1b2c3d",
        upstream: "origin/feature/login",
        ahead: 0,
        behind: 0,
        changedFiles: 0,
        stashCount: 0,
        operation: nil,
        baseBranch: "origin/dev",
        aheadOfBase: 0,
        behindBase: 0,
        lastFetch: nil,
        webURL: URL(string: "https://gitlab.example.com/top/live")
    )
}
