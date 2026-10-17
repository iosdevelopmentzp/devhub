import SwiftUI

struct WorktreeDeleteConfirm: View {
    @Environment(WorktreesStore.self) private var store

    let worktree: WorktreeInfo

    @State private var removesDerivedData = true
    @State private var deletesBranch = false

    private var derivedSize: Int64? { store.derivedSize(of: worktree) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(warnings, id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Tint.orange.color)
            }
            if derivedSize != nil {
                Toggle(derivedTitle, isOn: $removesDerivedData)
                    .font(.caption)
            }
            if worktree.branch != nil {
                Toggle("Delete branch (only if fully merged)", isOn: $deletesBranch)
                    .font(.caption)
            }
            InlineConfirm(
                text: "Remove the worktree folder \(worktree.folderName)?",
                confirmTitle: "Delete",
                tint: .red,
                onCancel: { store.cancelDelete() },
                onConfirm: {
                    Task { await store.delete(worktree, removeDerivedData: removesDerivedData && derivedSize != nil, deleteBranch: deletesBranch) }
                }
            )
        }
        .onAppear { deletesBranch = worktree.isMerged }
    }

    private var derivedTitle: String {
        "Delete DerivedData (\(derivedSize.map(DisplayFormat.bytes) ?? ""))"
    }

    private var warnings: [String] {
        var list: [String] = []
        if worktree.isDirty {
            list.append("\(worktree.changeCount) uncommitted changes will be lost.")
        }
        if worktree.isNotPushed, worktree.branch != nil {
            list.append(worktree.hasUpstream ? "\(worktree.ahead) commits are not pushed." : "The branch has no upstream. Its commits may exist only here.")
        }
        if worktree.isLocked {
            list.append("The worktree is locked.")
        }
        return list
    }
}

#Preview {
    WorktreeDeleteConfirm(worktree: WorktreeInfo.sample(path: "/tmp/example", branch: "feature/example"))
        .padding()
        .previewEnvironment()
}
