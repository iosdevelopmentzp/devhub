import Foundation
import DevHubDomain
import DevHubUI

struct LocalBranchRowModel: Identifiable, Equatable {
    let id: GitBranch.ID
    var name: String
    var icon: String
    var iconHint: String
    var usesAccentIcon: Bool
    var tags: [TagModel]
    var pullRequest: BranchPullRequestModel?
    var ticket: TicketModel?
    var dateText: String?
    var subject: String
    var worktreePath: String?
    var switchHint: String
    var canSwitch: Bool
    var switchConfirmation: String?
    var canUpdate: Bool
    var canBuild: Bool
    var canCreateWorktree: Bool
    var canDelete: Bool
    var canOpenPullRequest: Bool
    var pullRequestHint: String
    var pullRequestIconTint: Tint?
    var pullRequestMenuTitle: String
    var existingPullRequest: ExistingPullRequestModel?
    var areActionsEnabled: Bool
    var deleteMessage: String
    var showsForceToggle: Bool
    var configActions: [ConfigActionItemModel]

    static let preview = LocalBranchRowModel(
        id: "feature/ABC-2324-paid-call",
        name: "feature/ABC-2324-paid-call",
        icon: "arrow.triangle.branch",
        iconHint: "Local branch",
        usesAccentIcon: false,
        tags: [
            TagModel("local only", tint: .orange, systemImage: "icloud.slash", hint: "Never pushed: the commits exist only on this Mac"),
            TagModel("↑2", tint: .blue, hint: "2 commits not pushed")
        ],
        pullRequest: .preview,
        ticket: .preview,
        dateText: "visited 2 hr. ago · committed 3 days ago by kim",
        subject: "ABC-2324: Paid call payment",
        worktreePath: nil,
        switchHint: "Switch to this branch",
        canSwitch: true,
        switchConfirmation: nil,
        canUpdate: false,
        canBuild: true,
        canCreateWorktree: true,
        canDelete: true,
        canOpenPullRequest: false,
        pullRequestHint: "Push the branch first: a merge request needs it on the remote",
        pullRequestIconTint: nil,
        pullRequestMenuTitle: "New Merge Request…",
        existingPullRequest: nil,
        areActionsEnabled: true,
        deleteMessage: "Delete feature/ABC-2324-paid-call? It is not merged into dev; without force git refuses.",
        showsForceToggle: true,
        configActions: [.preview]
    )
}
