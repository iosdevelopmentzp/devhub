import SwiftUI

struct LocalBranchRow: View {
    @Environment(GitStore.self) private var store

    let branch: GitBranch

    @State private var isHovered = false

    private var isCurrent: Bool { branch.name == store.currentBranch }

    private var slot: String { "git.branchRow:\(branch.name)" }

    private var item: ActionItemContext {
        ActionItemContext(branch: branch.name, worktreePath: branch.worktreePath, rowID: branch.name)
    }

    private var isConfirmingDelete: Bool {
        store.confirmation == .deleteBranch(branch.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                IconTile(systemImage: "arrow.triangle.branch", tint: isCurrent ? .blue : .gray)
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 2) {
                    actions
                    OverflowMenu { menu }
                }
                .opacity(isHovered ? 1 : 0)
            }
            if isConfirmingDelete {
                InlineConfirm(
                    text: "\(branch.name) is not fully merged. Delete it with -D? Commits that exist nowhere else are lost.",
                    confirmTitle: "Delete",
                    tint: .red,
                    onCancel: { store.cancelConfirmation() },
                    onConfirm: { Task { await store.confirm() } }
                )
            }
            ConfigActionResults(placement: .gitBranchRow, slot: slot, showsResults: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isCurrent ? Color.accentColor.opacity(0.06) : (isHovered ? Theme.hover : .clear))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu { menu }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(branch.name)
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .copyOnClick(branch.name, label: "branch")
            LocalBranchTags(branch: branch, isCurrent: isCurrent)
            HStack(spacing: 4) {
                Text(branch.subject)
                    .lineLimit(1)
                    .hintWhenTruncated(branch.subject)
                if let date = branch.commitDate {
                    Text("· \(DisplayFormat.relative(date))")
                        .layoutPriority(1)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if isCurrent == false {
            if branch.worktreePath == nil {
                IconButton(systemImage: "arrow.right.circle", help: "Switch to this branch") {
                    Task { await store.switchTo(branch.name) }
                }
            } else {
                IconButton(systemImage: "square.stack.3d.up", help: "Show the checkout that has this branch") { store.showCheckout(of: branch) }
            }
        }
        IconButton(systemImage: "arrow.down.to.line", help: "Update: fast-forward from origin without switching") {
            Task { await store.update(branch: branch.name) }
        }
        if branch.worktreePath == nil {
            IconButton(systemImage: "plus.square.on.square", help: "Create a worktree for this branch") {
                Task { await store.createWorktree(for: branch.name) }
            }
        }
    }

    @ViewBuilder
    private var menu: some View {
        if isCurrent == false, branch.worktreePath == nil {
            Button("Switch", systemImage: "arrow.right.circle") { Task { await store.switchTo(branch.name) } }
        }
        Button("Update", systemImage: "arrow.down.to.line") { Task { await store.update(branch: branch.name) } }
        if branch.worktreePath == nil {
            Button("Create worktree", systemImage: "plus.square.on.square") { Task { await store.createWorktree(for: branch.name) } }
        }
        Divider()
        Button("Copy name", systemImage: "doc.on.doc") { store.copy(branch.name) }
        Button("Open on web", systemImage: "safari") { store.openOnWeb(branch: branch.name) }
        Button("New pull or merge request", systemImage: "arrow.triangle.pull") { store.openNewRequest(branch: branch.name) }
        ConfigActionMenuItems(placement: .gitBranchRow, slot: slot, item: item)
        if isCurrent == false, branch.worktreePath == nil {
            Divider()
            Button("Delete…", systemImage: "trash", role: .destructive) { Task { await store.deleteBranch(branch) } }
        }
    }
}

#Preview {
    LocalBranchRow(branch: GitBranch(name: "feature/example", upstream: nil, ahead: 0, behind: 0, isUpstreamGone: false, commitDate: Date(), worktreePath: nil, subject: "Add the example", lastVisit: nil, isMerged: false))
        .previewEnvironment()
}
