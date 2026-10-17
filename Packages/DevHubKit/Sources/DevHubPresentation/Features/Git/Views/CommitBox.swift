import SwiftUI
import DevHubDomain
import DevHubUI

struct CommitBox: View {
    @Environment(GitChangesStore.self) private var changes
    @Environment(GitStore.self) private var git

    var body: some View {
        @Bindable var changes = changes
        let model = model
        VStack(alignment: .leading, spacing: 8) {
            TextField("Commit message", text: $changes.message, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
            HStack(spacing: 8) {
                Toggle("Amend", isOn: $changes.amend)
                    .toggleStyle(.checkbox)
                    .hint("Add the staged changes to the last commit and replace its message. git commit --amend. After a push this needs a force push.")
                Text(model.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let busy = changes.busyTitle {
                    ProgressView()
                        .controlSize(.mini)
                    Text(busy + "…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
                Button("Commit & Push", systemImage: "arrow.up.circle") {
                    changes.commit(thenPush: true)
                }
                .fixedSize()
                .disabled(model.canCommitAndPush == false)
                .hint("Commit the staged files, then push the branch")
                Button("Commit", systemImage: "checkmark.circle") {
                    changes.commit(thenPush: false)
                }
                .buttonStyle(.borderedProminent)
                .fixedSize()
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(model.canCommit == false)
                .hint("Commit the staged files (⌘↩)")
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.base)
    }

    private var model: CommitBoxModel {
        CommitBoxMapper.model(
            staged: changes.staged,
            conflictedCount: changes.conflicted.count,
            isAmend: changes.amend,
            canCommit: changes.canCommit,
            isGitBusy: git.isBusy,
            branch: git.snapshot?.branch
        )
    }
}

#Preview {
    CommitBox()
        .previewEnvironment()
}
