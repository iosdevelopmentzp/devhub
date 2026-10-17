import SwiftUI
import DevHubDomain
import DevHubUI

struct WorktreesToolbar: View {
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(BuildStore.self) private var build

    @Binding var isConfirmingClean: Bool
    @Binding var isCreating: Bool

    @State private var branchName = ""
    @State private var isSubmitting = false
    @FocusState private var isBranchFieldFocused: Bool

    private var finished: [Worktree] {
        worktrees.finishedWorktrees(excluding: build.sourceWorktreeID)
    }

    var body: some View {
        ToolbarBar {
            VStack(alignment: .leading, spacing: 8) {
                header
                if isConfirmingClean {
                    confirmClean
                }
                if isCreating {
                    newWorktreeForm
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(CountText.invariant(worktrees.worktrees.count, "worktrees"))
                .font(.callout)
                .foregroundStyle(.secondary)
            Tag("base \(worktrees.baseBranch)", systemImage: "arrow.triangle.branch")
            if worktrees.linkedDerivedDataSize > 0 {
                Tag("DerivedData \(ByteFormat.text(worktrees.linkedDerivedDataSize))", tint: .blue, systemImage: "internaldrive")
                    .hint("Total DerivedData of linked worktrees. The main checkout is not counted.")
            }
            Spacer()
            if worktrees.isFetching || worktrees.isLoading {
                ProgressView()
                    .controlSize(.mini)
            }
            Button("Fetch", systemImage: "arrow.down.circle") {
                worktrees.fetchAndRefresh()
            }
            .hint("git fetch --prune origin, then re-read merged and remote-deleted branches")
            .disabled(worktrees.isFetching)
            if worktrees.missingCount > 0 {
                Button("Prune \(worktrees.missingCount)", systemImage: "scissors") {
                    worktrees.prune()
                }
                .hint("git worktree prune: forget worktrees whose folder is gone")
            }
            Button("Clean Finished (\(finished.count))…", systemImage: "sparkles") {
                isCreating = false
                isConfirmingClean = true
            }
            .disabled(finished.isEmpty)
            Button("New…", systemImage: "plus") {
                isConfirmingClean = false
                isCreating = true
                isBranchFieldFocused = true
            }
        }
    }

    private var confirmClean: some View {
        InlineConfirmation(
            "Remove \(CountText.invariant(finished.count, "finished worktrees")), their local branches and \(ByteFormat.text(worktrees.derivedDataSize(of: finished))) of DerivedData?",
            confirmTitle: "Remove",
            confirmRole: nil,
            systemImage: "sparkles",
            tint: .purple,
            titleFont: .caption.weight(.medium),
            onCancel: { isConfirmingClean = false },
            onConfirm: {
                isConfirmingClean = false
                worktrees.clean(finished)
            },
            details: {
                Text(finished.map(\.displayName).joined(separator: ", "))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text("Only clean, unlocked worktrees count. Worktrees with uncommitted changes and the build source stay.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            },
            extra: { EmptyView() }
        )
    }

    private var newWorktreeForm: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .foregroundStyle(.blue)
            TextField("Branch, e.g. ABC-2600-newFeature", text: $branchName)
                .textFieldStyle(.roundedBorder)
                .font(.callout.monospaced())
                .frame(width: 280)
                .focused($isBranchFieldFocused)
                .onSubmit(create)
            Text("from \(worktrees.baseBranch)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .hint("An existing local or remote branch is checked out as is. A new name branches from \(worktrees.baseBranch).")
            Spacer()
            if isSubmitting {
                ProgressView()
                    .controlSize(.mini)
            }
            Button("Cancel") {
                isCreating = false
                branchName = ""
            }
            Button("Create", action: create)
                .buttonStyle(.borderedProminent)
                .disabled(branchName.trimmed.isEmpty || isSubmitting)
        }
        .padding(8)
        .background(Color.blue.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func create() {
        guard branchName.trimmed.isEmpty == false, isSubmitting == false else { return }
        isSubmitting = true
        Task {
            let created = await worktrees.createAndBootstrap(branch: branchName)
            isSubmitting = false
            guard created else { return }
            branchName = ""
            isCreating = false
        }
    }
}
