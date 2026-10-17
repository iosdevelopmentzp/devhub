import SwiftUI

struct RemoteBranchRow: View {
    @Environment(GitStore.self) private var store

    let branch: RemoteBranch

    @State private var isHovered = false

    private var hasLocal: Bool { store.branches.hasLocal(branch.name) }

    var body: some View {
        HStack(spacing: 10) {
            IconTile(systemImage: "cloud", tint: .teal)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(branch.name)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(branch.fullName, label: "branch")
                    if hasLocal {
                        Tag("local copy", tint: .blue)
                    }
                }
                HStack(spacing: 4) {
                    Text(branch.author)
                        .lineLimit(1)
                    Text("· \(DisplayFormat.relative(branch.date))")
                        .fixedSize()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(branch.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .hintWhenTruncated(branch.subject)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 2) {
                IconButton(systemImage: "arrow.right.circle", help: hasLocal ? "Switch to the local branch" : "Check out: create a tracking branch") {
                    Task { await store.checkOutRemote(branch.name) }
                }
                IconButton(systemImage: "plus.square.on.square", help: "Create a worktree for this branch") {
                    Task { await store.createWorktree(for: branch.name) }
                }
                IconButton(systemImage: "safari", help: "Open on the web") { store.openOnWeb(branch: branch.name) }
                OverflowMenu {
                    Button("Copy name", systemImage: "doc.on.doc") { store.copy(branch.name) }
                }
            }
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isHovered ? Theme.hover : .clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Check out", systemImage: "arrow.right.circle") { Task { await store.checkOutRemote(branch.name) } }
            Button("Create worktree", systemImage: "plus.square.on.square") { Task { await store.createWorktree(for: branch.name) } }
            Button("Open on web", systemImage: "safari") { store.openOnWeb(branch: branch.name) }
            Button("Copy name", systemImage: "doc.on.doc") { store.copy(branch.name) }
        }
    }
}

#Preview {
    RemoteBranchRow(branch: RemoteBranch(name: "feature/other", author: "Ada", date: Date(), subject: "Add the other feature"))
        .previewEnvironment()
}
