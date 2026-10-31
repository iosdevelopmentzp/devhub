import SwiftUI
import DevHubDomain
import DevHubUI

struct WorktreeRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: WorktreeRowModel
    let isConfirmingDelete: Bool
    let isPickingLaunch: Bool
    let testRun: TestRunPanelModel?
    let canRunTests: Bool
    let onRequestDelete: () -> Void
    let onCancelDelete: () -> Void
    let onConfirmDelete: (_ deleteDerivedData: Bool, _ deleteBranch: Bool) -> Void
    let onBootstrap: () -> Void
    let onRequestLaunch: () -> Void
    let onCancelLaunch: () -> Void
    let onRunTests: () -> Void
    let onCancelTests: () -> Void
    let onDismissTests: () -> Void
    let onFixTests: (AIProvider) -> Void
    let onConfigAction: (ConfigActionItemModel.ID) -> Void

    @State private var deleteDerivedData = true
    @State private var deleteBranch = false

    var body: some View {
        RowContainer(isHighlighted: model.isHighlighted) { isHovered in
            row(isHovered: isHovered)
        }
        .onChange(of: isConfirmingDelete) { _, isConfirming in
            guard isConfirming else { return }
            deleteDerivedData = true
            deleteBranch = model.defaultDeleteBranch
        }
        .contextMenu { contextMenu }
    }

    private func row(isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                IconTile(systemImage: model.icon, tint: model.iconTint.color, size: 32)
                    .hint(model.iconHint)

                VStack(alignment: .leading, spacing: 4) {
                    titleLine
                    HStack(spacing: 6) {
                        Text(model.displayPath)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .copyOnClick(model.path, label: model.pathCopyLabel)
                        Text(model.head)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .copyOnClick(model.head, label: model.head)
                    }
                    statusLine
                    if let lastCommit = model.lastCommit {
                        HStack(spacing: 6) {
                            if let lastActivityText = model.lastActivityText {
                                Text(lastActivityText)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            Text(lastCommit)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .copyOnClick(lastCommit, label: lastCommit)
                        }
                    }
                }

                Spacer(minLength: 4)

                actions(isHovered: isHovered)
            }

            if isConfirmingDelete {
                deleteConfirmation
            }
            if isPickingLaunch {
                LaunchPicker(subject: model.title, onCancel: onCancelLaunch, onRun: { appActions.buildAndRun(worktreeID: model.id, on: $0) })
            }
            if let testRun {
                TestRunPanel(
                    model: testRun,
                    onCancel: onCancelTests,
                    onDismiss: onDismissTests,
                    onRunAgain: onRunTests,
                    onOpenFailure: { openFile($0.path, line: $0.line) },
                    onOpenIssue: { openFile($0.path, line: $0.line) },
                    onOpenResults: { appActions.open(URL(fileURLWithPath: $0)) },
                    onFix: onFixTests
                )
            }
        }
    }

    // MARK: Lines

    private var titleLine: some View {
        HStack(spacing: 6) {
            Text(model.title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .copyOnClick(model.titleCopyValue, label: model.title)
            ForEach(model.titleTags, id: \.self) { tag in
                ModelTag(model: tag)
            }
        }
    }

    private var statusLine: some View {
        HStack(spacing: 6) {
            ForEach(model.statusTags, id: \.self) { tag in
                ModelTag(model: tag)
            }
            if model.isBootstrapping {
                ProgressView()
                    .controlSize(.mini)
                Text(model.bootstrapRunningText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if let bootstrapTag = model.bootstrapTag {
                Button(action: onBootstrap) {
                    ModelTag(model: bootstrapTag)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Actions

    @ViewBuilder
    private func actions(isHovered: Bool) -> some View {
        if model.isBusy {
            ProgressView()
                .controlSize(.small)
                .frame(width: 24, height: 24)
        } else {
            HStack(spacing: 2) {
                IconButton(systemImage: "play.fill", help: "Build & Run this worktree: choose the simulator, environment and device ID first", tint: model.buildAndRunTint.color) {
                    onRequestLaunch()
                }
                .disabled(model.canBuildAndRun == false)
                IconButton(systemImage: "checkmark.diamond", help: "Run the tests of this worktree on the target simulator", tint: .green) {
                    onRunTests()
                }
                .disabled(canRunTests == false)
                IconButton(systemImage: "folder", help: "Open in Finder") {
                    appActions.openInFinder(path: model.path)
                }
                .disabled(model.canOpen == false)
                IconButton(systemImage: "hammer", help: "Open in Xcode") {
                    appActions.openInXcode(path: model.path)
                }
                .disabled(model.canOpen == false)
                IconButton(systemImage: "terminal", help: "Open in Terminal") {
                    appActions.openTerminal(at: model.path)
                }
                .disabled(model.canOpen == false)
                IconButton(systemImage: "trash", help: "Delete worktree", tint: model.deleteTint.color) {
                    onRequestDelete()
                }
                .disabled(model.canDelete == false)
            }
            .opacity(isHovered && isConfirmingDelete == false && isPickingLaunch == false ? 1 : 0)
        }
    }

    private func openFile(_ path: String?, line: Int?) {
        guard let path else { return }
        appActions.openFile(path: path, line: line)
    }

    private var deleteConfirmation: some View {
        InlineConfirmation(
            model.deleteTitle,
            confirmTitle: "Delete",
            confirmRole: .destructive,
            layout: .stacked(warnings: model.deleteWarnings),
            onCancel: onCancelDelete,
            onConfirm: { onConfirmDelete(deleteDerivedData, deleteBranch) }
        ) {
            Toggle(model.derivedDataLabel, isOn: $deleteDerivedData)
                .disabled(model.canDeleteDerivedData == false)
            if let deleteBranchLabel = model.deleteBranchLabel {
                Toggle(deleteBranchLabel, isOn: $deleteBranch)
                    .hint("git branch -d: refuses a branch that is not fully merged")
            }
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("Build & Run…", systemImage: "play.fill") { onRequestLaunch() }
            .disabled(model.canBuildAndRun == false)
        Button("Build & Run on Target Now", systemImage: "play.fill") {
            appActions.buildAndRun(worktreeID: model.id)
        }
        .disabled(model.canBuildAndRun == false)
        Button("Run Tests", systemImage: "checkmark.diamond") { onRunTests() }
            .disabled(canRunTests == false)
        if model.isBuildSource {
            Button("Stop Using as Build Source", systemImage: "play.slash") {
                appActions.useBuildSource(worktreeID: nil)
            }
        } else {
            Button("Use as Build Source", systemImage: "play") {
                appActions.useBuildSource(worktreeID: model.buildSourceIDToUse)
            }
            .disabled(model.canUseAsBuildSource == false)
        }
        Divider()
        Button("Open in Finder", systemImage: "folder") {
            appActions.openInFinder(path: model.path)
        }
        .disabled(model.canOpen == false)
        Button("Open in Xcode", systemImage: "hammer") {
            appActions.openInXcode(path: model.path)
        }
        .disabled(model.canOpen == false)
        Button("Open in Terminal", systemImage: "terminal") {
            appActions.openTerminal(at: model.path)
        }
        .disabled(model.canOpen == false)
        Menu("Start AI Session Here", systemImage: "sparkles") {
            ForEach(AIProvider.allCases, id: \.self) { provider in
                Button(AISessionRowMapper.toolTitle(for: provider), systemImage: "sparkles") {
                    appActions.startAISession(provider, at: model.path)
                }
            }
        }
        .disabled(model.canOpen == false)
        Divider()
        Button("Copy Path", systemImage: "doc.on.doc") {
            toaster.copy(model.path)
        }
        if let branch = model.branch {
            Button("Copy Branch Name", systemImage: "doc.on.doc") {
                toaster.copy(branch)
            }
        }
        if model.canRunBootstrap {
            Button(model.bootstrapTitle, systemImage: "wrench.and.screwdriver", action: onBootstrap)
        }
        ConfigActionMenuItems(items: model.configActions, onRun: onConfigAction)
        Divider()
        Button("Delete Worktree…", systemImage: "trash", role: .destructive) {
            onRequestDelete()
        }
        .disabled(model.canDelete == false)
    }
}

#Preview {
    WorktreeRow(
        model: .preview,
        isConfirmingDelete: false,
        isPickingLaunch: false,
        testRun: .preview,
        canRunTests: true,
        onRequestDelete: {},
        onCancelDelete: {},
        onConfirmDelete: { _, _ in },
        onBootstrap: {},
        onRequestLaunch: {},
        onCancelLaunch: {},
        onRunTests: {},
        onCancelTests: {},
        onDismissTests: {},
        onFixTests: { _ in },
        onConfigAction: { _ in }
    )
    .frame(width: 680)
    .previewEnvironment()
}
