import SwiftUI

struct CleanFinishedConfirm: View {
    @Environment(WorktreesStore.self) private var store

    let worktrees: [WorktreeInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(worktrees) { worktree in
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundStyle(Tint.red.color)
                        Text(worktree.title)
                            .font(.caption.monospaced())
                        if let size = store.derivedSize(of: worktree) {
                            Text(DisplayFormat.bytes(size))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            InlineConfirm(
                text: "Remove \(worktrees.count) finished worktrees with their DerivedData and merged branches? Dirty, locked and missing worktrees are skipped.",
                confirmTitle: "Remove",
                tint: .red,
                onCancel: { store.cancelClean() },
                onConfirm: { Task { await store.confirmClean() } }
            )
        }
    }
}

#Preview {
    CleanFinishedConfirm(worktrees: [WorktreeInfo.sample(path: "/tmp/old", branch: "fix/finished")])
        .padding()
        .previewEnvironment()
}
