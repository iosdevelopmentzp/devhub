import SwiftUI

struct GitHeaderCard: View {
    @Environment(GitStore.self) private var store

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                topRow
                if let operation = store.details.operation {
                    GitOperationBanner(operation: operation)
                }
                branchLine
                FlowLayout(spacing: 6, lineSpacing: 4) {
                    GitTags()
                }
                GitPullRequestLine()
                GitPillsBar()
            }
        }
    }

    private var topRow: some View {
        HStack(spacing: 8) {
            GitCheckoutPicker()
            Spacer(minLength: 8)
            if let busy = store.busyTitle {
                Text(busy)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let fetched = store.details.lastFetch {
                Text("fetched \(DisplayFormat.relative(fetched))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .hint("Time of the last fetch")
            }
            if store.isRefreshing || store.isBusy {
                ProgressView()
                    .controlSize(.small)
            } else {
                IconButton(systemImage: "arrow.clockwise", help: "Refresh") {
                    Task { await store.refresh() }
                }
            }
        }
    }

    private var branchLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(store.status.branch ?? (store.status.objectID == nil ? "No commits yet" : "Detached HEAD"))
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .truncationMode(.middle)
                .copyOnClick(store.status.branch ?? "", label: "branch")
            if store.status.shortHash.isEmpty == false {
                Text(store.status.shortHash)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .copyOnClick(store.status.objectID ?? "", label: "commit hash")
            }
        }
    }
}

#Preview {
    GitHeaderCard()
        .padding()
        .previewEnvironment()
}
