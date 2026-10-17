import SwiftUI

struct NewWorktreeCard: View {
    @Environment(WorktreesStore.self) private var store

    @Binding var isShown: Bool

    @State private var name = ""
    @State private var isCreating = false
    @FocusState private var isFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Branch to check out, or a new branch name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit { create() }
                Button("Cancel") { isShown = false }
                    .controlSize(.small)
                Button("Create", action: create)
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                    .disabled(trimmed.isEmpty || isCreating)
            }
            suggestions
            if trimmed.isEmpty == false {
                Text(plan)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let error = store.creationError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Tint.red.color)
            }
        }
        .padding(10)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .onAppear {
            isFocused = true
            store.setCreationError(nil)
        }
    }

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.candidates(matching: name), id: \.self) { candidate in
                Button {
                    name = candidate
                } label: {
                    HStack {
                        Text(candidate)
                            .font(.caption.monospaced())
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(store.branches.hasLocal(candidate) ? "local" : "remote")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var plan: String {
        let creation = store.creation(for: trimmed)
        guard let main = store.mainPath else { return creation.summary }
        let path = WorktreeLocation.path(repository: main, folder: store.worktreeSettings?.folder, branch: trimmed)
        let from = creation == .new(trimmed) ? " from \(store.baseBranch)" : ""
        return "\(creation.summary)\(from) in \(path)"
    }

    private func create() {
        guard trimmed.isEmpty == false, isCreating == false else { return }
        isCreating = true
        Task {
            let created = await store.createWorktree(named: trimmed)
            isCreating = false
            if created {
                isShown = false
            }
        }
    }
}

#Preview {
    @Previewable @State var shown = true
    NewWorktreeCard(isShown: $shown)
        .previewEnvironment()
}
