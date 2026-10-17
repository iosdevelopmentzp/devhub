import Foundation
import DevHubDomain
import DevHubUI

struct RemoteBranchRowModel: Identifiable, Equatable {
    let id: RemoteBranch.ID
    var remoteName: String
    var localName: String
    var tags: [TagModel]
    var mergeRequest: BranchMergeRequestModel?
    var ticket: TicketModel?
    var dateText: String?
    var author: String
    var subject: String
    var checkOutHint: String
    var canBuild: Bool
    var canCreateWorktree: Bool
    var areActionsEnabled: Bool

    static let preview = RemoteBranchRowModel(
        id: "origin/feature/ABC-2401-gifts",
        remoteName: "origin/feature/ABC-2401-gifts",
        localName: "feature/ABC-2401-gifts",
        tags: [TagModel("local", tint: .blue)],
        mergeRequest: .preview,
        ticket: .preview,
        dateText: "3 days ago",
        author: "sam",
        subject: "ABC-2401: Gift animation",
        checkOutHint: "Switch to the local branch",
        canBuild: true,
        canCreateWorktree: true,
        areActionsEnabled: true
    )
}
