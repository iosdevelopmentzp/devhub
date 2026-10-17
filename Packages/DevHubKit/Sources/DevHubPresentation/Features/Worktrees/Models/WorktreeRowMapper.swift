import Foundation
import DevHubDomain
import DevHubUI

enum WorktreeRowMapper {

    static func model(
        for worktree: Worktree,
        baseBranch: String,
        mainCheckoutPath: String?,
        derivedDataSize: Int64?,
        isBusy: Bool,
        isBootstrapping: Bool,
        isBuildSource: Bool,
        buildIsRunning: Bool
    ) -> WorktreeRowModel {
        WorktreeRowModel(
            id: worktree.id,
            title: worktree.displayName,
            titleCopyValue: worktree.branch ?? worktree.head,
            path: worktree.path,
            pathCopyLabel: worktree.path.abbreviatingHome,
            displayPath: displayPath(for: worktree, mainCheckoutPath: mainCheckoutPath),
            head: worktree.head,
            branch: worktree.branch,
            lastCommit: worktree.lastCommit.isEmpty ? nil : worktree.lastCommit,
            lastActivityText: worktree.lastActivity?.relativeDescription,
            icon: icon(for: worktree),
            iconHint: iconHint(for: worktree),
            iconTint: iconTint(for: worktree),
            isHighlighted: isBuildSource,
            titleTags: titleTags(for: worktree, isBuildSource: isBuildSource),
            statusTags: statusTags(for: worktree, baseBranch: baseBranch, derivedDataSize: derivedDataSize),
            isBootstrapping: isBootstrapping,
            bootstrapTag: isBootstrapping || worktree.needsBootstrap == false ? nil : bootstrapTag,
            canRunInit: worktree.needsBootstrap,
            isBusy: isBusy,
            isBuildSource: isBuildSource,
            canBuildAndRun: worktree.isMissing == false && buildIsRunning == false,
            canOpen: worktree.isMissing == false,
            canUseAsBuildSource: worktree.isMissing == false,
            buildSourceIDToUse: worktree.isMain ? nil : worktree.id,
            buildAndRunTint: .green,
            deleteTint: .red,
            canDelete: worktree.isMain == false && worktree.isMissing == false,
            deleteTitle: "Delete worktree \(worktree.displayName)?",
            deleteWarnings: WorktreeCleanupPolicy.deleteWarnings(for: worktree),
            defaultDeleteBranch: WorktreeCleanupPolicy.defaultDeleteBranch(for: worktree),
            derivedDataLabel: derivedDataLabel(size: derivedDataSize),
            canDeleteDerivedData: derivedDataSize != nil,
            deleteBranchLabel: worktree.branch.map { "Delete branch \($0)" }
        )
    }

    private static let bootstrapTag = TagModel(
        "needs init.sh",
        tint: .orange,
        systemImage: "wrench.and.screwdriver",
        hint: "Carthage/Build is missing in this worktree. Click to run init.sh (Carthage, SwiftGen)."
    )

    private static func displayPath(for worktree: Worktree, mainCheckoutPath: String?) -> String {
        guard worktree.isMain == false, let mainCheckoutPath else {
            return worktree.path.abbreviatingHome
        }
        let prefix = mainCheckoutPath + "/"
        guard worktree.path.hasPrefix(prefix) else { return worktree.path.abbreviatingHome }
        return String(worktree.path.dropFirst(prefix.count))
    }

    private static func icon(for worktree: Worktree) -> String {
        if worktree.isMain { return "house.fill" }
        if worktree.isMissing { return "questionmark.folder" }
        if worktree.isFinished { return "checkmark.seal.fill" }
        return worktree.kind == .agent ? "sparkles" : "arrow.triangle.branch"
    }

    private static func iconHint(for worktree: Worktree) -> String {
        if worktree.isMain { return "Main checkout" }
        if worktree.isMissing { return "The folder is gone. Prune removes the entry." }
        if worktree.isFinished { return "Finished: merged or the remote branch is deleted" }
        return worktree.kind == .agent ? "Claude Code agent worktree" : "Linked worktree"
    }

    private static func iconTint(for worktree: Worktree) -> Tint {
        if worktree.isMissing { return .red }
        if worktree.isFinished { return .purple }
        if worktree.isDirty { return .orange }
        return worktree.isMain ? .indigo : .blue
    }

    private static func titleTags(for worktree: Worktree, isBuildSource: Bool) -> [TagModel] {
        var tags: [TagModel] = []
        if worktree.isMain {
            tags.append(TagModel("main", tint: .indigo))
        }
        if worktree.kind == .agent {
            tags.append(TagModel(
                "claude",
                tint: .teal,
                systemImage: "sparkle",
                hint: "Lives in .claude/worktrees, the Claude Code agent folder. Gitignored."
            ))
        }
        if isBuildSource {
            tags.append(TagModel(
                "build source",
                tint: .blue,
                systemImage: "play.fill",
                hint: "Build & Run on the Simulators tab builds this checkout"
            ))
        }
        if worktree.isLocked {
            tags.append(TagModel(
                "locked",
                systemImage: "lock.fill",
                hint: "git worktree lock: protected from prune and remove"
            ))
        }
        return tags
    }

    private static func statusTags(for worktree: Worktree, baseBranch: String, derivedDataSize: Int64?) -> [TagModel] {
        var tags = [changesTag(for: worktree)]
        if let branchTag = branchTag(for: worktree, baseBranch: baseBranch) {
            tags.append(branchTag)
        }
        if worktree.ahead > 0 || worktree.behind > 0 {
            tags.append(TagModel(
                SyncText.text(ahead: worktree.ahead, behind: worktree.behind),
                hint: "Commits ahead / behind \(worktree.upstream ?? "upstream")"
            ))
        }
        if let derivedDataSize {
            tags.append(TagModel(
                ByteFormat.text(derivedDataSize),
                tint: .blue,
                systemImage: "internaldrive",
                hint: "DerivedData of this checkout"
            ))
        }
        return tags
    }

    private static func changesTag(for worktree: Worktree) -> TagModel {
        if worktree.isMissing {
            return TagModel("folder missing", tint: .red, systemImage: "questionmark.folder")
        }
        if worktree.isDirty {
            return TagModel("\(worktree.changedFiles) changed", tint: .orange, systemImage: "pencil")
        }
        return TagModel("clean", tint: .green, systemImage: "checkmark")
    }

    private static func branchTag(for worktree: Worktree, baseBranch: String) -> TagModel? {
        if worktree.isMerged {
            return TagModel("merged into \(BranchName(baseBranch).local)", tint: .purple, systemImage: "arrow.triangle.merge")
        }
        if worktree.isUpstreamGone {
            return TagModel("remote branch deleted", tint: .purple, systemImage: "icloud.slash")
        }
        if worktree.upstream == nil, worktree.isMissing == false, worktree.branch != nil {
            return TagModel("not pushed", tint: .orange, systemImage: "icloud.slash")
        }
        return nil
    }

    private static func derivedDataLabel(size: Int64?) -> String {
        guard let size else { return "No DerivedData found" }
        return "Delete DerivedData (\(ByteFormat.text(size)))"
    }
}
