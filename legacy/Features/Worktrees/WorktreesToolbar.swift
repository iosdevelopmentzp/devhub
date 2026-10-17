import SwiftUI

struct WorktreesToolbar: View {
    @Environment(WorktreesStore.self) private var store

    @Binding var showsCreation: Bool

    private var isWorking: Bool { store.workingTitle != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Tag("base \(store.baseBranch)", tint: .blue, systemImage: "arrow.triangle.branch")
                    .copyOnClick(store.baseBranch, label: "base branch")
                if store.derivedData.totalBytes > 0 {
                    Tag("DerivedData \(DisplayFormat.bytes(store.derivedData.totalBytes))", tint: .gray, systemImage: "internaldrive")
                        .hint("Size of \(store.derivedData.root)")
                }
                Spacer(minLength: 8)
                if let title = store.workingTitle {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    ProgressView()
                        .controlSize(.small)
                } else if store.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    IconButton(systemImage: "arrow.clockwise", help: "Refresh worktrees") {
                        Task { await store.refresh() }
                    }
                }
            }
            ActionBar(items: items)
            if let pending = store.pendingClean {
                CleanFinishedConfirm(worktrees: pending)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var items: [ActionItem] {
        [
            ActionItem("Fetch", systemImage: "arrow.down.circle", hint: "git fetch --prune origin", priority: 2, isDisabled: isWorking) {
                Task { await store.fetch() }
            },
            ActionItem("Prune", systemImage: "scissors", hint: "git worktree prune: forget worktrees whose folder is gone", priority: 1, isDisabled: isWorking) {
                Task { await store.prune() }
            },
            ActionItem("Clean Finished…", systemImage: "sparkles", hint: "Remove worktrees whose branch is merged or deleted on the remote", priority: 3, isDisabled: isWorking) {
                store.askClean()
            },
            ActionItem("New worktree", systemImage: "plus", hint: "Create a worktree for a branch", priority: 4, isDisabled: isWorking) {
                showsCreation.toggle()
            }
        ]
    }
}

#Preview {
    @Previewable @State var shows = false
    WorktreesToolbar(showsCreation: $shows)
        .previewEnvironment()
}
