import Foundation
import DevHubDomain
import DevHubUI

struct GitHeaderModel: Equatable {
    var branchTitle: String
    var branchCopyValue: String
    var head: String
    var statusTag: TagModel
    var upstreamTag: TagModel?
    var tags: [TagModel]
    var stashTag: TagModel?
    var ticket: TicketModel?
    var showsMergeRequestLine: Bool
    var operationText: String?
    var canContinueOperation: Bool
    var actions: [GitHeaderActionModel]
    var webBranch: String?
    var newMergeRequestHint: String
    var branchOnWebHint: String
    var forcePushMessage: String
    var rebaseMessage: String

    static let preview = GitHeaderModel(
        branchTitle: "feature/ABC-2324-paid-call",
        branchCopyValue: "feature/ABC-2324-paid-call",
        head: "a1b2c3d",
        statusTag: TagModel("2 changed", tint: .orange, systemImage: "pencil", hint: "2 files with changes that are not committed"),
        upstreamTag: TagModel("origin/feature/ABC-2324-paid-call", systemImage: "icloud"),
        tags: [TagModel("↑1 to push", tint: .blue, hint: "1 local commits are not on origin/feature/ABC-2324-paid-call yet")],
        stashTag: TagModel("3 stashed", systemImage: "tray.full", hint: "3 entries in git stash. Click to see them."),
        ticket: .preview,
        showsMergeRequestLine: true,
        operationText: nil,
        canContinueOperation: false,
        actions: [.preview],
        webBranch: "feature/ABC-2324-paid-call",
        newMergeRequestHint: "Open a new merge request for feature/ABC-2324-paid-call on GitLab",
        branchOnWebHint: "Open feature/ABC-2324-paid-call on GitLab",
        forcePushMessage: "Force push feature/ABC-2324-paid-call?",
        rebaseMessage: "Rebase feature/ABC-2324-paid-call on origin/dev?"
    )
}
