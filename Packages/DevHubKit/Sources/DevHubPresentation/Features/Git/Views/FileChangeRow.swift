import SwiftUI
import DevHubDomain
import DevHubUI

struct FileChangeRow: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster

    let model: FileChangeRowModel
    let onToggleDiff: () -> Void
    let onStage: () -> Void
    let onUnstage: () -> Void
    let onDiscard: () -> Void

    @State private var isConfirmingDiscard = false

    var body: some View {
        RowContainer(verticalPadding: 5) { isHovered in
            row(isHovered: isHovered)
        }
        .contextMenu { menu }
    }

    private func row(isHovered: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 10)
                Text(model.letter)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(model.letterTint.color)
                    .frame(width: 16)
                    .hint(model.letterHint)
                HStack(spacing: 6) {
                    Text(model.fileName)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(model.detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .hintWhenTruncated(model.path)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                actions
                    .opacity(isHovered && isConfirmingDiscard == false ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleDiff()
            }
            if isConfirmingDiscard {
                discardConfirmation
            }
            if let diff = model.diff {
                DiffView(model: diff, scrollScope: nil, highlightedLineID: nil, onOpenLine: nil)
                    .padding(.leading, 18)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 2) {
            IconButton(systemImage: model.stageIcon, help: model.stageHint) {
                if model.isStaged {
                    onUnstage()
                } else {
                    onStage()
                }
            }
            if model.canOpen {
                IconButton(systemImage: "square.and.pencil", help: "Open the file in the editor chosen in Settings") {
                    appActions.openFile(path: model.fullPath)
                }
            }
            IconButton(systemImage: "folder", help: "Show the file in Finder") {
                appActions.revealInFinder(path: model.revealPath)
            }
            IconButton(systemImage: "doc.on.doc", help: "Copy the path: \(model.path)") {
                toaster.copy(model.path)
            }
            IconButton(systemImage: "arrow.uturn.backward", help: model.discardHint, tint: .red) {
                isConfirmingDiscard = true
            }
        }
        .disabled(model.areActionsEnabled == false)
    }

    private var discardConfirmation: some View {
        InlineConfirmation(
            model.discardMessage,
            confirmTitle: model.discardTitle,
            confirmRole: .destructive,
            onCancel: { isConfirmingDiscard = false },
            onConfirm: {
                isConfirmingDiscard = false
                onDiscard()
            }
        )
    }

    @ViewBuilder
    private var menu: some View {
        Button(model.isExpanded ? "Hide Diff" : "Show Diff", systemImage: "text.alignleft") { onToggleDiff() }
        if model.canOpen {
            Button("Open in Editor", systemImage: "square.and.pencil") { appActions.openFile(path: model.fullPath) }
            Button("Open with Default App", systemImage: "arrow.up.forward.app") { appActions.openWithDefaultApp(path: model.fullPath) }
        }
        Button("Show in Finder", systemImage: "folder") { appActions.revealInFinder(path: model.revealPath) }
        Divider()
        Button("Copy Path", systemImage: "doc.on.doc") { toaster.copy(model.path) }
        Button("Copy Full Path", systemImage: "doc.on.doc") { toaster.copy(model.fullPath) }
        Button("Copy File Name", systemImage: "doc.on.doc") { toaster.copy(model.fileName) }
        if let diffText = model.diffText {
            Button("Copy Diff", systemImage: "doc.on.clipboard") { toaster.copy(diffText, label: "diff of \(model.fileName)") }
        }
    }
}

#Preview {
    FileChangeRow(model: .preview, onToggleDiff: {}, onStage: {}, onUnstage: {}, onDiscard: {})
        .previewEnvironment()
}
