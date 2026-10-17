import Foundation
import DevHubDomain

struct MockGitRepository: GitRepository {

    func webURL(checkoutPath: String, remote: String) async -> URL? {
        URL(string: "https://gitlab.com/example/app")
    }

    func state(checkoutPath: String, mainPath: String, settings: GitSettings) async throws -> GitRepositoryState {
        let now = Date()
        return GitRepositoryState(
            snapshot: GitSnapshot(
                branch: "ABC-2489-leaderboardFollowStatusReset",
                head: "0362516c7",
                upstream: "origin/ABC-2489-leaderboardFollowStatusReset",
                ahead: 1,
                behind: 0,
                changedFiles: 3,
                stashCount: 1,
                operation: nil,
                baseBranch: "origin/dev",
                aheadOfBase: 4,
                behindBase: 12,
                lastFetch: now.addingTimeInterval(-1_800),
                webURL: URL(string: "https://gitlab.com/example/app")
            ),
            localBranches: [
                GitBranch(name: "ABC-2489-leaderboardFollowStatusReset", upstream: "origin/ABC-2489-leaderboardFollowStatusReset", ahead: 1, behind: 0, isGone: false, isMerged: false, subject: "Reset a Leaderboard follow status", commitDate: now.addingTimeInterval(-7_200), lastVisited: now.addingTimeInterval(-600), worktreePath: mainPath),
                GitBranch(name: "dev", upstream: "origin/dev", ahead: 0, behind: 12, isGone: false, isMerged: true, subject: "Merge branch 'ABC-1881' into 'dev'", commitDate: now.addingTimeInterval(-3_600), lastVisited: now.addingTimeInterval(-86_400), worktreePath: nil),
                GitBranch(name: "ABC-2245-leaderboarLocalizationFixes", upstream: "origin/ABC-2245-leaderboarLocalizationFixes", ahead: 0, behind: 0, isGone: true, isMerged: true, subject: "Rename the Leaderboard diamonds keys", commitDate: now.addingTimeInterval(-172_800), lastVisited: now.addingTimeInterval(-259_200), worktreePath: "\(mainPath)/.worktrees/ABC-2245")
            ],
            remoteBranches: [
                RemoteBranch(name: "origin/dev", author: "GitLab", subject: "Merge branch 'ABC-1881' into 'dev'", commitDate: now.addingTimeInterval(-3_600)),
                RemoteBranch(name: "origin/ABC-2510-newOnboarding", author: "Sam", subject: "Onboarding step 2", commitDate: now.addingTimeInterval(-20_000))
            ],
            history: [
                GitCommit(hash: "0362516c73ac02ae16961be5dce11137392a397a", shortHash: "0362516c7", author: "Alex", date: now.addingTimeInterval(-7_200), subject: "ABC-2489: Reset a Leaderboard follow status", isPushed: false, refs: [GitCommitRef(kind: .head, name: "HEAD"), GitCommitRef(kind: .localBranch, name: "ABC-2489-leaderboardFollowStatusReset")]),
                GitCommit(hash: "cf17ab4f1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", shortHash: "cf17ab4f1", author: "GitLab", date: now.addingTimeInterval(-90_000), subject: "Merge branch 'ABC-1881-neverCarriedSettled' into 'dev'", isPushed: true, refs: [GitCommitRef(kind: .remoteBranch, name: "origin/dev"), GitCommitRef(kind: .tag, name: "v4.12")], isMerge: true)
            ],
            stashes: [
                GitStash(index: 0, branch: "ABC-2489-leaderboardFollowStatusReset", message: "half done: follow button state", date: now.addingTimeInterval(-3_600))
            ]
        )
    }

    func commitSubjects(from base: String, to head: String, in path: String) async throws -> [String] {
        ["ABC-2489: Reset the follow status", "ABC-2489: Add a test for the reset"]
    }

    func pullRequestTemplate(in path: String) async -> String? {
        nil
    }

    func perform(_ command: GitCommand, in path: String) async throws {
        try await Task.sleep(for: .milliseconds(600))
    }
}
