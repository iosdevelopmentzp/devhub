import SwiftUI
import DevHubDomain
import DevHubUI

struct LocalBranchRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: LocalBranchRowModel
    let isConfirmingDelete: Bool
    let isConfirmingSwitch: Bool
    let isPickingLaunch: Bool
    let isShowingExistingPullRequest: Bool
    let onSwitch: (SwitchBranchUseCase.Plan) -> Void
    let onRequestSwitch: () -> Void
    let onCancelSwitch: () -> Void
    let onUpdate: () -> Void
    let onSelectCheckout: (String) -> Void
    let onRequestDelete: () -> Void
    let onCancelDelete: () -> Void
    let onDelete: (_ force: Bool) -> Void
    let onRequestPullRequest: () -> Void
    let onCancelPullRequest: () -> Void
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onConfigAction: (ConfigActionItemModel.ID) -> Void

    @State private var force = false

    var body: some View {
        RowContainer(verticalPadding: 7) { isHovered in
            row(isHovered: isHovered)
        }
        .contextMenu { menu }
    }

    private func row(isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: model.icon)
                    .foregroundStyle(model.usesAccentIcon ? Color.accentColor : .secondary)
                    .frame(width: 16)
                    .padding(.top, 2)
                    .hint(model.iconHint)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .copyOnClick(model.name, label: model.name)
                        ForEach(model.tags, id: \.self) { tag in
                            ModelTag(model: tag)
                        }
                        if let pullRequest = model.pullRequest {
                            BranchPullRequestTags(model: pullRequest)
                        }
                        if let ticket = model.ticket {
                            TicketChip(model: ticket)
                        }
                    }
                    HStack(spacing: 6) {
                        if let dateText = model.dateText {
                            Text(dateText)
                                .font(.caption2.weight(.medium))
                        }
                        Text(model.subject)
                            .font(.caption2)
                            .lineLimit(1)
                            .copyOnClick(model.subject, label: model.subject)
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                actions(isHovered: isHovered)
            }
            if isConfirmingDelete {
                deleteConfirmation
            }
            if isConfirmingSwitch, let message = model.switchConfirmation {
                InlineConfirmation(
                    message,
                    confirmTitle: "Stash & Switch",
                    confirmRole: nil,
                    systemImage: "tray.and.arrow.down",
                    tint: .orange,
                    onCancel: onCancelSwitch,
                    onConfirm: {
                        onCancelSwitch()
                        onSwitch(.stashSwitchPop)
                    }
                ) {
                    Button("Switch Anyway") {
                        onCancelSwitch()
                        onSwitch(.switchOnly)
                    }
                }
            }
            if isPickingLaunch {
                LaunchPicker(subject: model.name, onCancel: onCancelLaunch, onRun: { appActions.buildAndRun(branch: model.name, on: $0) })
            }
            if isShowingExistingPullRequest, let existing = model.existingPullRequest {
                InlineConfirmation(
                    existing.message,
                    confirmTitle: existing.openTitle,
                    confirmRole: nil,
                    systemImage: "arrow.triangle.pull",
                    tint: .blue,
                    onCancel: onCancelPullRequest,
                    onConfirm: {
                        onCancelPullRequest()
                        appActions.open(existing.url)
                    }
                )
            }
        }
    }

    private func actions(isHovered: Bool) -> some View {
        HoverActions(isVisible: isHovered && isShowingInlinePanel == false, count: 6, spacing: 2) {
            IconButton(systemImage: "arrow.right.circle", help: model.switchHint) {
                requestSwitch()
            }
            .disabled(model.canSwitch == false)
            IconButton(systemImage: "arrow.down.circle", help: "Update: fast-forward from the remote without switching") {
                onUpdate()
            }
            .disabled(model.canUpdate == false)
            IconButton(systemImage: "play.fill", help: "Build & Run this branch: choose the simulator, environment and device ID first (uses or creates a worktree)", tint: .green) {
                onRequestLaunch()
            }
            .disabled(model.canBuild == false)
            IconButton(systemImage: "plus.rectangle.on.folder", help: "Create a worktree for this branch") {
                appActions.createWorktree(branch: model.name)
            }
            .disabled(model.canCreateWorktree == false)
            IconButton(systemImage: "arrow.triangle.pull", help: model.pullRequestHint, tint: model.pullRequestIconTint?.color ?? .primary) {
                onRequestPullRequest()
            }
            .disabled(model.canOpenPullRequest == false)
            IconButton(systemImage: "trash", help: "Delete the local branch", tint: .red) {
                onRequestDelete()
            }
            .disabled(model.canDelete == false)
        }
        .disabled(model.areActionsEnabled == false)
    }

    private var isShowingInlinePanel: Bool {
        isConfirmingDelete || isConfirmingSwitch || isPickingLaunch || isShowingExistingPullRequest
    }

    private func requestSwitch() {
        guard model.switchConfirmation != nil else {
            onSwitch(.switchOnly)
            return
        }
        onRequestSwitch()
    }

    private var deleteConfirmation: some View {
        InlineConfirmation(
            model.deleteMessage,
            confirmTitle: "Delete",
            confirmRole: .destructive,
            onCancel: onCancelDelete,
            onConfirm: {
                onCancelDelete()
                onDelete(force)
            }
        ) {
            if model.showsForceToggle {
                Toggle("Force (-D)", isOn: $force)
                    .toggleStyle(.checkbox)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button("Switch", systemImage: "arrow.right.circle") { requestSwitch() }
            .disabled(model.canSwitch == false)
        Button("Update (fast-forward)", systemImage: "arrow.down.circle") { onUpdate() }
            .disabled(model.canUpdate == false)
        Button("Build & Run…", systemImage: "play.fill") { onRequestLaunch() }
            .disabled(model.canBuild == false)
        Button("Build & Run on Target Now", systemImage: "play.fill") { appActions.buildAndRun(branch: model.name) }
            .disabled(model.canBuild == false)
        if let path = model.worktreePath {
            Button("Open Worktree in Terminal", systemImage: "terminal") { appActions.openTerminal(at: path) }
            Button("Use This Checkout in Git Tab", systemImage: "folder") { onSelectCheckout(path) }
        } else {
            Button("Create Worktree", systemImage: "plus.rectangle.on.folder") { appActions.createWorktree(branch: model.name) }
        }
        Divider()
        Button("Copy Name", systemImage: "doc.on.doc") { toaster.copy(model.name) }
        Button("Open on Web", systemImage: "globe") { appActions.openBranchOnWeb(model.name) }
        Button(model.pullRequestMenuTitle, systemImage: "arrow.triangle.pull") { onRequestPullRequest() }
            .disabled(model.canOpenPullRequest == false)
        if let pullRequest = model.pullRequest {
            Button("Open Merge Request in GitLab", systemImage: "globe") { appActions.open(pullRequest.webURL) }
            Button("Copy Link with Title", systemImage: "text.bubble") { toaster.copy(pullRequest.linkText, label: "Link with title") }
        }
        Divider()
        ConfigActionMenuItems(items: model.configActions, onRun: onConfigAction)
        Divider()
        Button("Delete…", systemImage: "trash", role: .destructive) { onRequestDelete() }
            .disabled(model.canDelete == false)
    }
}

#Preview {
    LocalBranchRow(
        model: .preview,
        isConfirmingDelete: false,
        isConfirmingSwitch: false,
        isPickingLaunch: false,
        isShowingExistingPullRequest: false,
        onSwitch: { _ in },
        onRequestSwitch: {},
        onCancelSwitch: {},
        onUpdate: {},
        onSelectCheckout: { _ in },
        onRequestDelete: {},
        onCancelDelete: {},
        onDelete: { _ in },
        onRequestPullRequest: {},
        onCancelPullRequest: {},
        onRequestLaunch: {},
        onCancelLaunch: {},
        onConfigAction: { _ in }
    )
    .previewEnvironment()
}
