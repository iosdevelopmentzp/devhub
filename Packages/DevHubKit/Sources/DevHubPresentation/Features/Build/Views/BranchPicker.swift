import SwiftUI
import DevHubDomain
import DevHubUI

struct BranchPicker: View {
    @Environment(GitStore.self) private var git

    let onPick: (String) -> Void

    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Search branches", text: $query)
                .textFieldStyle(.roundedBorder)
            if git.state == nil {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(choices) { item in
                        Button {
                            onPick(item.name)
                        } label: {
                            HStack {
                                Text(item.name)
                                    .font(.callout)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text(item.detail)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(height: 320)
            Text("Local branches by your last visit, then remote branches by last commit. A branch without a worktree gets one under .worktrees on the next run.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(width: 380)
        .task {
            if git.state == nil {
                await git.refresh()
            }
        }
    }

    private var choices: [BranchChoiceModel] {
        BranchChoiceMapper.choices(
            local: git.state?.localBranches ?? [],
            remote: git.state?.remoteBranches ?? [],
            remoteName: git.remote,
            query: query
        )
    }
}

#Preview {
    BranchPicker { _ in }
        .previewEnvironment()
}
