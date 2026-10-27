import Foundation
import DevHubDomain
import DevHubUI

enum LocalBranchRowMapper {
    static func model(
        for branch: GitBranch,
        currentBranch: String?,
        worktree: Worktree?,
        mark: BranchMark,
        openPullRequest: PullRequestSummary?,
        baseName: String,
        changedFiles: Int,
        ticket: TicketSettings,
        words: CodeHostWords,
        isBuildRunning: Bool,
        isBusy: Bool,
        configActions: [ConfigActionItemModel]
    ) -> LocalBranchRowModel {
        let isCurrent = branch.name == currentBranch
        let isCheckedOut = branch.worktreePath != nil
        let isInOtherCheckout = isCurrent == false && isCheckedOut
        let isOnRemote = branch.upstream != nil && branch.isGone == false
        return LocalBranchRowModel(
            id: branch.id,
            name: branch.name,
            icon: isCurrent ? "checkmark.circle.fill" : (isCheckedOut ? "rectangle.stack" : "arrow.triangle.branch"),
            iconHint: isCurrent ? "Checked out here" : (isCheckedOut ? "Checked out in another worktree" : "Local branch"),
            usesAccentIcon: isCurrent,
            isPinned: mark.isPinned,
            pinIcon: mark.isPinned ? "star.fill" : "star",
            pinHint: mark.isPinned ? "Unpin: return the branch to its usual place" : "Pin to the top of the list",
            pinMenuTitle: mark.isPinned ? "Unpin" : "Pin to Top",
            labels: BranchLabelMapper.tags(for: mark.labels),
            note: mark.note.isEmpty ? nil : mark.note,
            markMenuTitle: mark.labels.isEmpty && mark.note.isEmpty ? "Add Labels & Note…" : "Edit Labels & Note…",
            tags: checkoutTags(isCurrent: isCurrent, worktree: worktree) + trackingTags(branch, baseName: baseName, words: words),
            pullRequest: BranchPullRequestMapper.model(for: openPullRequest, words: words),
            ticket: TicketMapper.model(for: [branch.name], ticket: ticket),
            dateText: dateText(branch),
            subject: branch.subject,
            worktreePath: branch.worktreePath,
            switchHint: isInOtherCheckout ? "Checked out in another worktree" : "Switch to this branch",
            canSwitch: isCurrent == false && isInOtherCheckout == false,
            switchConfirmation: SwitchBranchUseCase.plan(changedFiles: changedFiles) == .stashSwitchPop
                ? "You have \(CountText.count(changedFiles, "changed file")). Stash them, switch to \(branch.name) and bring them back?"
                : nil,
            canUpdate: isOnRemote,
            canBuild: isBuildRunning == false,
            canCreateWorktree: isCheckedOut == false,
            canDelete: isCurrent == false && isCheckedOut == false,
            canOpenPullRequest: isOnRemote || openPullRequest != nil,
            pullRequestHint: pullRequestHint(openPullRequest, isOnRemote: isOnRemote, words: words),
            pullRequestIconTint: openPullRequest == nil ? nil : .blue,
            pullRequestMenuTitle: openPullRequest == nil ? "New \(words.requestTitle)…" : "Show \(words.requestTitle)…",
            existingPullRequest: openPullRequest.map { existingModel($0, words: words) },
            areActionsEnabled: isBusy == false,
            deleteMessage: branch.isMerged || branch.isGone
                ? "Delete local branch \(branch.name)?"
                : "Delete \(branch.name)? It is not merged into \(baseName); without force git refuses.",
            showsForceToggle: branch.isMerged == false,
            configActions: configActions
        )
    }

    private static func pullRequestHint(_ request: PullRequestSummary?, isOnRemote: Bool, words: CodeHostWords) -> String {
        if let request {
            return "\(words.requestSentence) \(words.reference(request.iid)) into \(request.targetBranch) is open"
        }
        return isOnRemote
            ? "New \(words.request): title, description and labels in DevHub"
            : "Push the branch first: a \(words.request) needs it on the remote"
    }

    private static func existingModel(_ request: PullRequestSummary, words: CodeHostWords) -> ExistingPullRequestModel {
        ExistingPullRequestModel(
            message: "\(words.requestSentence) \(words.reference(request.iid)) into \(request.targetBranch) already exists: \(request.title)",
            openTitle: "Open \(words.reference(request.iid))",
            url: request.webURL
        )
    }

    private static func checkoutTags(isCurrent: Bool, worktree: Worktree?) -> [TagModel] {
        if isCurrent {
            return [TagModel("current", tint: .blue)]
        }
        guard let worktree else { return [] }
        var tags = [
            TagModel(worktree.isMain ? "main checkout" : "worktree", tint: .teal, systemImage: "rectangle.stack", hint: worktree.path)
        ]
        if worktree.changedFiles > 0 {
            tags.append(TagModel("\(worktree.changedFiles) changed there", tint: .orange))
        }
        return tags
    }

    private static func trackingTags(_ branch: GitBranch, baseName: String, words: CodeHostWords) -> [TagModel] {
        var tags: [TagModel] = []
        if branch.isGone {
            tags.append(
                TagModel(
                    "remote deleted",
                    tint: .purple,
                    systemImage: "icloud.slash",
                    hint: "Its branch on the remote was deleted, usually after the \(words.request) was merged"
                )
            )
        } else if branch.upstream == nil {
            tags.append(TagModel("local only", tint: .orange, systemImage: "icloud.slash", hint: "Never pushed: the commits exist only on this Mac"))
        }
        if branch.isMerged {
            tags.append(TagModel("merged", tint: .purple, systemImage: "arrow.triangle.merge", hint: "All its commits are in \(baseName). Safe to delete."))
        }
        if branch.ahead > 0 {
            tags.append(TagModel(SyncText.ahead(branch.ahead), tint: .blue, hint: "\(branch.ahead) commits not pushed"))
        }
        if branch.behind > 0 {
            tags.append(TagModel(SyncText.behind(branch.behind), tint: .orange, hint: "Behind its remote. Update fast-forwards it without switching."))
        }
        return tags
    }

    private static func dateText(_ branch: GitBranch) -> String? {
        let committed = branch.commitDate.map { "committed \($0.relativeDescription)\(branch.author.map { " by \($0)" } ?? "")" }
        let parts = [branch.lastVisited.map { "visited \($0.relativeDescription)" }, committed].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
