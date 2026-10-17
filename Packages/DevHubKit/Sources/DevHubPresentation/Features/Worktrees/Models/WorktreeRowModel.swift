import Foundation
import DevHubDomain
import DevHubUI

struct WorktreeRowModel: Identifiable, Equatable {
    let id: Worktree.ID
    var title: String
    var titleCopyValue: String
    var path: String
    var pathCopyLabel: String
    var displayPath: String
    var head: String
    var branch: String?
    var lastCommit: String?
    var lastActivityText: String?
    var icon: String
    var iconHint: String
    var iconTint: Tint
    var isHighlighted: Bool
    var titleTags: [TagModel]
    var statusTags: [TagModel]
    var isBootstrapping: Bool
    var bootstrapTag: TagModel?
    var canRunInit: Bool
    var isBusy: Bool
    var isBuildSource: Bool
    var canBuildAndRun: Bool
    var canOpen: Bool
    var canUseAsBuildSource: Bool
    var buildSourceIDToUse: Worktree.ID?
    var buildAndRunTint: Tint
    var deleteTint: Tint
    var canDelete: Bool
    var deleteTitle: String
    var deleteWarnings: [String]
    var defaultDeleteBranch: Bool
    var derivedDataLabel: String
    var canDeleteDerivedData: Bool
    var deleteBranchLabel: String?
    var configActions: [ConfigActionItemModel]

    static let preview = WorktreeRowModel(
        id: "/Users/dev/Projects/ExampleApp/.claude/worktrees/ABC-2600-newFeature",
        title: "ABC-2600-newFeature",
        titleCopyValue: "ABC-2600-newFeature",
        path: "/Users/dev/Projects/ExampleApp/.claude/worktrees/ABC-2600-newFeature",
        pathCopyLabel: "~/Projects/ExampleApp/.claude/worktrees/ABC-2600-newFeature",
        displayPath: ".claude/worktrees/ABC-2600-newFeature",
        head: "a1b2c3d",
        branch: "ABC-2600-newFeature",
        lastCommit: "Add the new feature screen",
        lastActivityText: "2 hr. ago",
        icon: "sparkles",
        iconHint: "Claude Code agent worktree",
        iconTint: .orange,
        isHighlighted: false,
        titleTags: [
            TagModel("claude", tint: .teal, systemImage: "sparkle", hint: "Lives in .claude/worktrees, the Claude Code agent folder. Gitignored.")
        ],
        statusTags: [
            TagModel("3 changed", tint: .orange, systemImage: "pencil"),
            TagModel("↑2", hint: "Commits ahead / behind origin/ABC-2600-newFeature"),
            TagModel("1.2 GB", tint: .blue, systemImage: "internaldrive", hint: "DerivedData of this checkout")
        ],
        isBootstrapping: false,
        bootstrapTag: TagModel(
            "needs init.sh",
            tint: .orange,
            systemImage: "wrench.and.screwdriver",
            hint: "Carthage/Build is missing in this worktree. Click to run init.sh (Carthage, SwiftGen)."
        ),
        canRunInit: true,
        isBusy: false,
        isBuildSource: false,
        canBuildAndRun: true,
        canOpen: true,
        canUseAsBuildSource: true,
        buildSourceIDToUse: "/Users/dev/Projects/ExampleApp/.claude/worktrees/ABC-2600-newFeature",
        buildAndRunTint: .green,
        deleteTint: .red,
        canDelete: true,
        deleteTitle: "Delete worktree ABC-2600-newFeature?",
        deleteWarnings: ["3 uncommitted changes will be lost (git worktree remove --force)."],
        defaultDeleteBranch: false,
        derivedDataLabel: "Delete DerivedData (1.2 GB)",
        canDeleteDerivedData: true,
        deleteBranchLabel: "Delete branch ABC-2600-newFeature",
        configActions: [.preview]
    )
}
