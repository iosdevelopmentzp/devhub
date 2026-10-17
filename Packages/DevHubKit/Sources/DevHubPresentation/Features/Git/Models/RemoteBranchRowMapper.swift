import Foundation
import DevHubDomain
import DevHubUI

enum RemoteBranchRowMapper {

    static func model(
        for branch: RemoteBranch,
        localBranchNames: Set<String>,
        openMergeRequest: MergeRequestSummary?,
        ticketURLTemplate: String,
        checkoutPath: (String) -> String?,
        isBuildRunning: Bool,
        isBusy: Bool
    ) -> RemoteBranchRowModel {
        let localName = BranchName(branch.name).local
        let hasLocal = localBranchNames.contains(localName)
        return RemoteBranchRowModel(
            id: branch.id,
            remoteName: branch.name,
            localName: localName,
            tags: hasLocal ? [TagModel("local", tint: .blue)] : [],
            mergeRequest: BranchMergeRequestMapper.model(for: openMergeRequest),
            ticket: TicketMapper.model(for: [localName], template: ticketURLTemplate),
            dateText: branch.commitDate?.relativeDescription,
            author: branch.author,
            subject: branch.subject,
            checkOutHint: hasLocal ? "Switch to the local branch" : "Check out as a new local branch",
            canBuild: isBuildRunning == false,
            canCreateWorktree: checkoutPath(localName) == nil,
            areActionsEnabled: isBusy == false
        )
    }
}
