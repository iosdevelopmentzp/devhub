import Foundation
import DevHubDomain

extension MockData {
    package static let worktrees: [Worktree] = [
        worktree(
            "~/Documents/Projects/example-app",
            branch: "ABC-2489-leaderboardFollowStatusReset",
            kind: .main,
            ahead: 1,
            lastCommit: "Reset a Leaderboard follow status when a favorite change contradicts it",
            lastActivity: ago(hours: 2)
        ),
        worktree(
            "~/Documents/Projects/example-app/.claude/worktrees/ABC-2501",
            branch: "ABC-2501-giftsBannerRedesign",
            changedFiles: 7,
            behind: 3,
            lastCommit: "WIP banner layout",
            lastActivity: ago(minutes: 35)
        ),
        worktree(
            "~/Documents/Projects/example-app/.claude/worktrees/ABC-1881",
            branch: "ABC-1881-neverCarriedSettled",
            behind: 12,
            isMerged: true,
            lastCommit: "neverCarried waits Timeouts.settled instead of the 10 s absence window",
            lastActivity: ago(days: 2)
        ),
        worktree(
            "~/Documents/Projects/example-app/.claude/worktrees/NO-TASK",
            branch: "NO-TASK-mrClaudeAutoReview",
            isUpstreamGone: true,
            lastCommit: "Add MR auto review job",
            lastActivity: ago(days: 1)
        ),
        worktree(
            "~/Documents/Projects/example-app-extra",
            branch: "ABC-2510-newOnboarding",
            kind: .linked,
            ahead: 4,
            lastCommit: "Onboarding step 2",
            lastActivity: ago(hours: 6),
            needsBootstrap: true
        ),
        worktree(
            "~/Documents/Projects/example-app/.claude/worktrees/hotfix",
            branch: "hotfix-login-crash",
            isMissing: true,
            lastCommit: "",
            lastActivity: nil
        )
    ]

    package static let derivedDataSizes: [Worktree.ID: Int64] = [
        "~/Documents/Projects/example-app": 6_800_000_000,
        "~/Documents/Projects/example-app/.claude/worktrees/ABC-2501": 3_100_000_000,
        "~/Documents/Projects/example-app/.claude/worktrees/ABC-1881": 2_900_000_000,
        "~/Documents/Projects/example-app/.claude/worktrees/NO-TASK": 2_400_000_000
    ]

    private static func worktree(
        _ path: String,
        branch: String,
        kind: Worktree.Kind = .agent,
        changedFiles: Int = 0,
        isUpstreamGone: Bool = false,
        ahead: Int = 0,
        behind: Int = 0,
        isMerged: Bool = false,
        isMissing: Bool = false,
        lastCommit: String,
        lastActivity: Date?,
        needsBootstrap: Bool = false
    ) -> Worktree {
        Worktree(
            id: path,
            path: path,
            branch: branch,
            head: "a1b2c3d",
            kind: kind,
            isLocked: false,
            isMissing: isMissing,
            changedFiles: changedFiles,
            upstream: isUpstreamGone ? nil : "origin/\(branch)",
            isUpstreamGone: isUpstreamGone,
            ahead: ahead,
            behind: behind,
            isMerged: isMerged,
            lastCommit: lastCommit,
            lastActivity: lastActivity,
            needsBootstrap: needsBootstrap
        )
    }
}
