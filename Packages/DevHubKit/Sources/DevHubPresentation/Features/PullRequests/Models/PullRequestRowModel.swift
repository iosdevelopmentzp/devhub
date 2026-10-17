import Foundation
import DevHubDomain
import DevHubUI

struct PullRequestRowModel: Identifiable, Equatable {
    let id: PullRequestSummary.ID
    var reference: String
    var title: String
    var icon: String
    var iconTint: Tint
    var iconHint: String
    var isNew: Bool
    var ticket: TicketModel?
    var linkText: String
    var author: String
    var authorTint: Tint?
    var authorHint: String
    var sourceBranch: String
    var targetBranch: String
    var dateText: String?
    var dateHint: String?
    var statsText: String?
    var tags: [TagModel]
    var pipelineTag: TagModel?
    var pipelineURL: URL?
    var labelTags: [TagModel]
    var usesPlainTags: Bool
    var webURL: URL?
    var canCheckOut: Bool
    var canCreateWorktree: Bool
    var canSwitchBranch: Bool
    var worktreePath: String?
    var canFixThreads: Bool
    var primaryActions: [PullRequestActionModel]
    var actions: [PullRequestActionModel]
    var mergeTitle: String
    var autoMergeTitle: String
    var squashByDefault: Bool
    var removeSourceBranchByDefault: Bool
    var isBusy: Bool
    var isExpanded: Bool

    var hasTags: Bool {
        ticket != nil || pipelineTag != nil || tags.isEmpty == false || labelTags.isEmpty == false
    }

    static let preview = PullRequestRowModel(
        id: 1842,
        reference: "!1842",
        title: "ABC-2324: Paid call payment",
        icon: "arrow.triangle.pull",
        iconTint: .blue,
        iconHint: "Open",
        isNew: true,
        ticket: .preview,
        linkText: "!1842 ABC-2324: Paid call payment\nhttps://gitlab.com/example/app/-/merge_requests/1842",
        author: "sam",
        authorTint: nil,
        authorHint: "Opened by sam",
        sourceBranch: "feature/ABC-2324-paid-call",
        targetBranch: "dev",
        dateText: "updated 12 min ago",
        dateHint: "opened 5 days ago",
        statsText: "+120 −30 · 7 files · 3 commits",
        tags: [
            TagModel("needs approval", tint: .orange, hint: "GitLab merge status: not_approved"),
            TagModel("2 open threads", tint: .orange, systemImage: "bubble.left.and.bubble.right"),
        ],
        pipelineTag: .icon("checkmark.circle.fill", tint: .green, hint: "Pipeline passed 1 hr. ago. Click to open it."),
        pipelineURL: nil,
        labelTags: [TagModel("feature", tint: .secondary, systemImage: "tag", hint: "Label on GitLab")],
        usesPlainTags: false,
        webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842"),
        canCheckOut: true,
        canCreateWorktree: true,
        canSwitchBranch: true,
        worktreePath: nil,
        canFixThreads: true,
        primaryActions: [.preview],
        actions: [PullRequestActionModel(id: .markDraft, title: "Mark as Draft", systemImage: "pencil.circle", hint: "Add the Draft mark")],
        mergeTitle: "Merge !1842 into dev?",
        autoMergeTitle: "Merge !1842 into dev when the pipeline passes?",
        squashByDefault: true,
        removeSourceBranchByDefault: true,
        isBusy: false,
        isExpanded: false
    )
}
