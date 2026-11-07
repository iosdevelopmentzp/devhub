import SwiftUI
import DevHubUI

struct PullRequestFileSidebar: View {
    let model: PullRequestFileSidebarModel?
    let selectedID: String?
    @Binding var query: String
    let actions: PullRequestDetailActions
    let onSelect: (String) -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let model {
                header(model)
                Divider()
                list(model)
            } else {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.base)
    }

    private func header(_ model: PullRequestFileSidebarModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(model.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                IconButton(systemImage: "chevron.up", help: "Show the diff of the previous file") { step(-1, in: model) }
                    .disabled(neighbour(-1, in: model) == nil)
                IconButton(systemImage: "chevron.down", help: "Show the diff of the next file") { step(1, in: model) }
                    .disabled(neighbour(1, in: model) == nil)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(model.progressText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                ProgressView(value: model.progress)
                    .controlSize(.small)
                    .tint(.green)
            }
            .hint("Files marked as viewed with the box of a file or the circle of a row")
            SearchField(prompt: "Filter files", text: $query, focus: $isSearchFocused)
            if model.groups.isEmpty == false {
                FlowLayout(spacing: 6) {
                    ForEach(model.groups) { group in
                        Button {
                            actions.toggleFileGroup(group.id)
                        } label: {
                            Tag(group.title, tint: group.tint.color, systemImage: group.icon)
                                .opacity(group.isHidden ? 0.75 : 1)
                        }
                        .buttonStyle(.plain)
                        .hint(group.hint)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func list(_ model: PullRequestFileSidebarModel) -> some View {
        if let emptyText = model.emptyText {
            Text(emptyText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(14)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(model.rows) { row in
                        PullRequestFileSidebarRow(model: row, isSelected: row.id == selectedID, actions: actions) {
                            onSelect(row.id)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func neighbour(_ offset: Int, in model: PullRequestFileSidebarModel) -> String? {
        let ids = model.rows.map(\.id)
        guard ids.isEmpty == false else { return nil }
        guard let selectedID, let index = ids.firstIndex(of: selectedID) else { return offset > 0 ? ids.first : nil }
        let next = index + offset
        guard ids.indices.contains(next) else { return nil }
        return ids[next]
    }

    private func step(_ offset: Int, in model: PullRequestFileSidebarModel) {
        guard let id = neighbour(offset, in: model) else { return }
        onSelect(id)
    }
}

#Preview {
    PullRequestFileSidebar(model: .preview, selectedID: PullRequestFileSidebarRowModel.preview.id, query: .constant(""), actions: .preview, onSelect: { _ in })
        .previewEnvironment()
        .frame(width: 280, height: 400)
}
