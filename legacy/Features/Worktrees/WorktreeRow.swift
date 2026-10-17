import SwiftUI

struct WorktreeRow: View {
    @Environment(WorktreesStore.self) private var store
    @Environment(Toaster.self) private var toaster

    let worktree: WorktreeInfo

    @State private var isHovered = false

    private var slot: String { "worktrees.row:\(worktree.path)" }

    private var isBusy: Bool { store.busyPaths.contains(worktree.path) }

    private var item: ActionItemContext {
        ActionItemContext(branch: worktree.branch, worktreePath: worktree.path, rowID: worktree.path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                IconTile(systemImage: icon, tint: tint)
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
            if store.pendingDelete == worktree.path {
                WorktreeDeleteConfirm(worktree: worktree)
            }
            ConfigActionResults(placement: .worktreesRow, slot: slot, showsResults: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.hover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu { menuItems }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(worktree.title)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
            Text(worktree.path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .copyOnClick(worktree.path, label: "path")
            WorktreeTags(worktree: worktree)
            if let subject = worktree.lastCommitSubject {
                HStack(spacing: 4) {
                    Text(subject)
                        .lineLimit(1)
                        .hintWhenTruncated(subject)
                    if let date = worktree.lastCommitDate {
                        Text("· \(DisplayFormat.relative(date))")
                            .layoutPriority(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
        } else {
            if worktree.needsBootstrap {
                Button("Bootstrap", systemImage: "play.fill") {
                    Task { await store.runBootstrap(path: worktree.path) }
                }
                .controlSize(.small)
                .fixedSize()
                .hint("Run the bootstrap script in this worktree")
            }
            HStack(spacing: 2) {
                if worktree.isMissing {
                    IconButton(systemImage: "scissors", help: "Prune: forget worktrees whose folder is gone") {
                        Task { await store.prune() }
                    }
                } else {
                    IconButton(systemImage: "folder", help: "Open in Finder") { store.projectActions.reveal(worktree.path, title: "Open in Finder") }
                    IconButton(systemImage: "terminal", help: "Open in Terminal") { store.projectActions.openTerminal(at: worktree.path) }
                    IconButton(systemImage: "hammer", help: "Open in editor") { store.projectActions.openInEditor(at: worktree.path) }
                }
                OverflowMenu { menuItems }
            }
            .opacity(isHovered ? 1 : 0)
        }
    }

    @ViewBuilder
    private var menuItems: some View {
        Button("Copy path", systemImage: "doc.on.doc") { toaster.copy(worktree.path, label: "path") }
        if let branch = worktree.branch {
            Button("Copy branch", systemImage: "doc.on.doc") { toaster.copy(branch, label: branch) }
        }
        ConfigActionMenuItems(placement: .worktreesRow, slot: slot, item: item)
        if worktree.isMain == false, worktree.isMissing == false {
            Divider()
            Button("Delete…", systemImage: "trash", role: .destructive) { store.askDelete(worktree) }
        }
    }

    private var icon: String {
        if worktree.isMissing { return "exclamationmark.triangle" }
        return worktree.isMain ? "house" : "arrow.triangle.branch"
    }

    private var tint: Tint {
        if worktree.isMissing { return .red }
        if worktree.isMain { return .indigo }
        return worktree.isFinished ? .purple : .blue
    }
}

#Preview {
    WorktreeRow(worktree: WorktreeInfo.sample(path: "/tmp/example-feature", branch: "feature/example"))
        .previewEnvironment()
}
