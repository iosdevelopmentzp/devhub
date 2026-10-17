import SwiftUI

struct CommitBox: View {
    @Environment(GitStore.self) private var store

    private var canCommit: Bool {
        guard store.isBusy == false, store.status.branch != nil || store.amend else { return false }
        let hasMessage = store.commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return (store.stagedCount > 0 && hasMessage) || (store.amend && (hasMessage || store.stagedCount == 0))
    }

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 8) {
            TextField("Commit message", text: $store.commitMessage, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 10) {
                Toggle("Amend", isOn: $store.amend)
                    .font(.caption)
                    .hint("Replace the last commit. An empty message keeps the old one.")
                Text(store.stagedCount == 0 ? "Stage files to commit" : "\(store.stagedCount) staged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("Commit & Push") { Task { await store.commit(thenPush: true) } }
                    .disabled(canCommit == false)
                    .hint("git commit, then git push")
                Button("Commit") { Task { await store.commit(thenPush: false) } }
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .disabled(canCommit == false)
                    .hint("git commit (⌘↩)")
            }
            .controlSize(.small)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    CommitBox()
        .padding()
        .previewEnvironment()
}
