import SwiftUI
import DevHubDomain
import DevHubUI

struct HiddenFileRow: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster

    let model: HiddenFileRowModel
    let onToggleDiff: () -> Void
    let onTrack: (GitTrackMode) -> Void

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
                    ForEach(model.flags, id: \.text) { flag in
                        PlainTag(flag.text, tint: Tint.purple.color)
                            .hint(flag.hint)
                    }
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
                InlineConfirmation(
                    model.discardMessage,
                    confirmTitle: "Discard",
                    confirmRole: .destructive,
                    onCancel: { isConfirmingDiscard = false },
                    onConfirm: {
                        isConfirmingDiscard = false
                        onTrack(.discardChanges)
                    }
                )
            }
            if let diff = model.diff {
                DiffView(model: diff, scrollScope: nil, highlightedLineID: nil, onOpenLine: nil)
                    .padding(.leading, 18)
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 2) {
            IconButton(systemImage: "eye", help: model.trackHint) {
                onTrack(.keepChanges)
            }
            if model.canOpen {
                IconButton(systemImage: "square.and.pencil", help: "Open the file in the editor chosen in Settings") {
                    appActions.openFile(path: model.fullPath)
                }
            }
            IconButton(systemImage: "folder", help: "Show the file in Finder") {
                appActions.revealInFinder(path: model.revealPath)
            }
            if model.hasChanges {
                OverflowMenu {
                    trackItems
                }
            }
        }
        .disabled(model.areActionsEnabled == false)
    }

    @ViewBuilder
    private var trackItems: some View {
        Button("Track Again", systemImage: "eye") { onTrack(.keepChanges) }
        if model.hasChanges {
            Button("Stash Changes and Track Again", systemImage: "tray.and.arrow.down") { onTrack(.stashChanges) }
            Button("Discard Changes and Track Again…", systemImage: "arrow.uturn.backward") { isConfirmingDiscard = true }
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button(model.isExpanded ? "Hide Diff" : "Show Diff", systemImage: "text.alignleft") { onToggleDiff() }
        trackItems
        Divider()
        if model.canOpen {
            Button("Open in Editor", systemImage: "square.and.pencil") { appActions.openFile(path: model.fullPath) }
        }
        Button("Show in Finder", systemImage: "folder") { appActions.revealInFinder(path: model.revealPath) }
        Divider()
        Button("Copy Path", systemImage: "doc.on.doc") { toaster.copy(model.path) }
        Button("Copy Full Path", systemImage: "doc.on.doc") { toaster.copy(model.fullPath) }
        if let diffText = model.diffText {
            Button("Copy Diff", systemImage: "doc.on.clipboard") { toaster.copy(diffText, label: "diff of \(model.fileName)") }
        }
    }
}

#Preview {
    HiddenFileRow(model: .preview, onToggleDiff: {}, onTrack: { _ in })
        .previewEnvironment()
}
