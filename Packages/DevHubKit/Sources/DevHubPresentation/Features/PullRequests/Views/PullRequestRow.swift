import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestRow: View {
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let model: PullRequestRowModel
    let details: PullRequestDetailsModel?
    let isSelected: Bool
    let isNarrow: Bool
    let isPickingLaunch: Bool
    let detailActions: PullRequestDetailActions
    let onToggle: () -> Void
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onAction: (PullRequestActionModel.Kind) -> Void
    let onMerge: (_ kind: PullRequestActionModel.Kind, _ squash: Bool, _ removeSourceBranch: Bool) -> Void

    @State private var confirmingMerge: PullRequestActionModel.Kind?

    var body: some View {
        RowContainer(verticalPadding: 7, isHighlighted: isSelected) { isHovered in
            row(isHovered: isHovered)
        }
        .contextMenu { menu }
        .animation(.snappy(duration: 0.18), value: confirmingMerge)
    }

    private func row(isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            summary(isHovered: isHovered)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggle)
            if details != nil {
                PullRequestActionBar(
                    model: model,
                    isPickingLaunch: isPickingLaunch,
                    onRequestLaunch: onRequestLaunch,
                    onCancelLaunch: onCancelLaunch,
                    onAction: onAction,
                    onMerge: onMerge,
                    onFixThreads: detailActions.fixThreads,
                    onConfigAction: detailActions.runConfigAction
                )
                .padding(.leading, 26)
            } else {
                if let kind = confirmingMerge {
                    MergeConfirmation(kind: kind, model: model, onCancel: { confirmingMerge = nil }) { kind, squash, remove in
                        confirmingMerge = nil
                        onMerge(kind, squash, remove)
                    }
                    .padding(.leading, 26)
                }
                if isPickingLaunch {
                    LaunchPicker(subject: model.sourceBranch, onCancel: onCancelLaunch, onRun: { appActions.buildAndRun(branch: remoteBranch, on: $0) })
                        .padding(.leading, 26)
                }
            }
            if let details {
                PullRequestDetailsView(model: details, actions: detailActions)
                    .padding(.leading, 26)
            }
        }
    }

    private func summary(isHovered: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: model.isExpanded && isSelected == false ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 10)
                .padding(.top, 4)
            Image(systemName: model.icon)
                .foregroundStyle(model.iconTint.color)
                .frame(width: 16)
                .padding(.top, 2)
                .hint(model.iconHint)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    if model.isNew {
                        StatusDot(color: Tint.blue.color)
                            .hint("Updated since your last visit")
                    }
                    Text(model.reference)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .copyOnClick(model.reference, label: model.reference)
                    Text(model.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .hintWhenTruncated(model.title)
                }
                if isNarrow {
                    narrowFacts
                } else {
                    facts
                }
                if model.hasTags {
                    FlowLayout(spacing: 6) {
                        if let ticket = model.ticket {
                            TicketChip(model: ticket)
                        }
                        if let pipeline = model.pipelineTag {
                            Button {
                                appActions.open(model.pipelineURL)
                            } label: {
                                ModelTag(model: pipeline)
                            }
                            .buttonStyle(.plain)
                        }
                        ForEach(model.tags, id: \.self) { tag in
                            ModelTag(model: tag, isPlain: model.usesPlainTags)
                        }
                        ForEach(model.labelTags, id: \.self) { tag in
                            ModelTag(model: tag, isPlain: model.usesPlainTags)
                        }
                    }
                }
            }
            Spacer(minLength: 4)
            if isNarrow == false, details == nil {
                actions(isHovered: isHovered)
            } else if model.isBusy {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var facts: some View {
        HStack(spacing: 6) {
            author
            if let dateText = model.dateText {
                Text(dateText)
                    .font(.caption2.weight(.medium))
                    .fixedSize()
                    .hint(model.dateHint)
            }
            branches
            if let statsText = model.statsText {
                Text(statsText)
                    .font(.caption2.monospacedDigit())
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .foregroundStyle(.secondary)
    }

    private var narrowFacts: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                author
                if let dateText = model.dateText {
                    Text(dateText)
                        .font(.caption2.weight(.medium))
                        .lineLimit(1)
                        .hint(model.dateHint)
                }
            }
            HStack(spacing: 6) {
                branches
            }
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var author: some View {
        if model.author.isEmpty == false {
            Label(model.author, systemImage: "person.crop.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(model.authorTint?.color ?? .primary)
                .lineLimit(1)
                .fixedSize()
                .hint(model.authorHint)
        }
    }

    @ViewBuilder
    private var branches: some View {
        Text(model.sourceBranch)
            .font(.caption2.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .copyOnClick(model.sourceBranch, label: model.sourceBranch)
        Image(systemName: "arrow.right")
            .font(.system(size: 8, weight: .semibold))
        Text(model.targetBranch)
            .font(.caption2.monospaced())
            .lineLimit(1)
            .truncationMode(.middle)
            .layoutPriority(1)
            .copyOnClick(model.targetBranch, label: model.targetBranch)
    }

    @ViewBuilder
    private func actions(isHovered: Bool) -> some View {
        if model.isBusy {
            ProgressView()
                .controlSize(.small)
                .frame(width: 24, height: 24)
        } else {
            hoverActions(isHovered: isHovered)
        }
    }

    private func hoverActions(isHovered: Bool) -> some View {
        HoverActions(isVisible: isHovered, count: model.primaryActions.count + 4, spacing: 2) {
            ForEach(model.primaryActions) { action in
                IconButton(systemImage: action.systemImage, help: action.hint, tint: action.tint?.color ?? .primary) {
                    perform(action.id)
                }
            }
            IconButton(systemImage: "play.fill", help: "Build & Run the source branch: choose the simulator, environment and device ID first (uses or creates a worktree)", tint: .green) {
                onRequestLaunch()
            }
            .disabled(model.canCheckOut == false)
            if let path = model.worktreePath {
                IconButton(systemImage: "terminal", help: "Open the worktree of the source branch in Terminal") {
                    appActions.openTerminal(at: path)
                }
            } else {
                IconButton(systemImage: "plus.rectangle.on.folder", help: "Create a worktree for the source branch") {
                    appActions.createWorktree(branch: remoteBranch)
                }
                .disabled(model.canCreateWorktree == false)
            }
            IconButton(systemImage: "globe", help: words.openTitle) {
                appActions.open(model.webURL)
            }
            .disabled(model.webURL == nil)
            OverflowMenu {
                PullRequestMenuItems(model: model, actions: model.actions, onPerform: perform, onFixThreads: detailActions.fixThreads, onConfigAction: detailActions.runConfigAction)
            }
        }
    }

    private func perform(_ kind: PullRequestActionModel.Kind) {
        guard kind != .merge, kind != .mergeWhenPipelinePasses else {
            confirmingMerge = kind
            return
        }
        onAction(kind)
    }

    @ViewBuilder
    private var menu: some View {
        Button(words.openTitle, systemImage: "globe") { appActions.open(model.webURL) }
        if let openWindow = detailActions.openWindow {
            Button("Open in Window", systemImage: "macwindow", action: openWindow)
        }
        if model.primaryActions.isEmpty == false {
            Divider()
            ForEach(model.primaryActions) { action in
                Button(action.title, systemImage: action.systemImage) { perform(action.id) }
            }
        }
        Divider()
        Button("Build & Run…", systemImage: "play.fill") { onRequestLaunch() }
            .disabled(model.canCheckOut == false)
        Button("Build & Run on Target Now", systemImage: "play.fill") { appActions.buildAndRun(branch: remoteBranch) }
            .disabled(model.canCheckOut == false)
        Button("Create Worktree", systemImage: "plus.rectangle.on.folder") { appActions.createWorktree(branch: remoteBranch) }
            .disabled(model.canCreateWorktree == false)
        Divider()
        PullRequestMenuItems(model: model, actions: model.actions, onPerform: perform, onFixThreads: detailActions.fixThreads, onConfigAction: detailActions.runConfigAction)
    }

    private var remoteBranch: String {
        appActions.remoteRef(for: model.sourceBranch)
    }
}

#Preview {
    PullRequestRow(model: .preview, details: .preview, isSelected: false, isNarrow: false, isPickingLaunch: false, detailActions: .preview, onToggle: {}, onRequestLaunch: {}, onCancelLaunch: {}, onAction: { _ in }, onMerge: { _, _, _ in })
        .previewEnvironment()
}
