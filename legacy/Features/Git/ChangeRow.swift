import SwiftUI

struct ChangeRow: View {
    @Environment(GitStore.self) private var store

    let change: GitChange
    let group: GitChange.Group

    @State private var isHovered = false

    private var key: String { store.diffKey(change, group) }

    private var isExpanded: Bool { store.expandedDiff == key }

    private var letter: Character { change.letter(in: group) }

    private var isConfirmingDiscard: Bool {
        store.confirmation == .discard(path: change.path, group: group)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(String(letter))
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(tint.color)
                    .frame(width: 20, height: 20)
                    .background(tint.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                    .hint(GitChangeLetter.title(letter))
                VStack(alignment: .leading, spacing: 1) {
                    Text(change.fileName)
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if change.folder.isEmpty == false || change.originalPath != nil {
                        Text(subtitle)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2) {
                    actions
                }
                .opacity(isHovered || isExpanded ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { Task { await store.toggleDiff(change, in: group) } }
            if isConfirmingDiscard {
                InlineConfirm(
                    text: group == .untracked ? "Delete the new file \(change.fileName)? This cannot be undone." : "Discard the changes to \(change.fileName)? This cannot be undone.",
                    confirmTitle: group == .untracked ? "Delete" : "Discard",
                    tint: .red,
                    onCancel: { store.cancelConfirmation() },
                    onConfirm: { Task { await store.confirm() } }
                )
            }
            if isExpanded {
                if let diff = store.diffs[key] {
                    GitDiffView(diff: diff)
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(isHovered ? Theme.hover : .clear)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Open in editor", systemImage: "hammer") { store.openInEditor(change) }
            Button("Copy path", systemImage: "doc.on.doc") { store.copy(change.path) }
        }
    }

    @ViewBuilder
    private var actions: some View {
        if group == .staged {
            IconButton(systemImage: "minus.circle", help: "Unstage") { Task { await store.unstage(change) } }
        } else {
            IconButton(systemImage: "plus.circle", help: group == .conflict ? "Mark as resolved (stage)" : "Stage") { Task { await store.stage(change) } }
        }
        IconButton(systemImage: "hammer", help: "Open in editor") { store.openInEditor(change) }
        if group != .conflict {
            IconButton(systemImage: "arrow.uturn.backward", help: group == .untracked ? "Delete this new file" : "Discard changes", tint: .red) {
                store.askDiscard(change, in: group)
            }
        }
    }

    private var subtitle: String {
        if let original = change.originalPath {
            return "from \(original)"
        }
        return change.folder
    }

    private var tint: Tint {
        switch letter {
        case "A", "?": .green
        case "D": .red
        case "R", "C": .purple
        case "!": .red
        default: .orange
        }
    }
}

#Preview {
    ChangeRow(change: GitChange(path: "Sources/App/Model.swift", originalPath: nil, index: "M", worktree: "."), group: .staged)
        .previewEnvironment()
}
