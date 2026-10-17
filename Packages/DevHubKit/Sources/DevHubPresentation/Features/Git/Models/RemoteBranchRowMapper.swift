import Foundation
import DevHubDomain
import DevHubUI

enum RemoteBranchRowMapper {

    static func model(
        for branch: RemoteBranch,
        remote: String,
        localBranchNames: Set<String>,
        openPullRequest: PullRequestSummary?,
        ticket: TicketSettings,
        checkoutPath: (String) -> String?,
        isBuildRunning: Bool,
        isBusy: Bool
    ) -> RemoteBranchRowModel {
        let localName = BranchName(branch.name, remote: remote).local
        let hasLocal = localBranchNames.contains(localName)
        return RemoteBranchRowModel(
            id: branch.id,
            remoteName: branch.name,
            localName: localName,
            tags: hasLocal ? [TagModel("local", tint: .blue)] : [],
            pullRequest: BranchPullRequestMapper.model(for: openPullRequest),
            ticket: TicketMapper.model(for: [localName], ticket: ticket),
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
