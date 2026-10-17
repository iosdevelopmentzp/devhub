import SwiftUI

struct ChangesView: View {
    @Environment(GitStore.self) private var store
    @Environment(ProjectSession.self) private var session

    private var sections: [(group: GitChange.Group, changes: [GitChange])] {
        store.grouped.compactMap { section in
            let list = section.changes.filter { session.matchesSearch($0.path) }
            return list.isEmpty ? nil : (section.group, list)
        }
    }

    private var firstUnstagedGroup: GitChange.Group? {
        sections.first { $0.group == .unstaged || $0.group == .untracked }?.group
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                CommitBox()
                    .padding(14)
                if store.status.isClean {
                    EmptyState(systemImage: "checkmark.circle", title: "No local changes", text: "The working tree of this checkout is clean.")
                        .frame(height: 200)
                } else if sections.isEmpty {
                    ContentUnavailableView.search(text: session.searchText)
                } else {
                    ForEach(sections, id: \.group) { section in
                        header(for: section.group, count: section.changes.count)
                        ForEach(section.changes) { change in
                            ChangeRow(change: change, group: section.group)
                                .id(store.diffKey(change, section.group))
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private func header(for group: GitChange.Group, count: Int) -> some View {
        SectionHeader("\(group.title) · \(count)") {
            if group == .staged {
                Button("Unstage All") { Task { await store.unstageAll() } }
            } else if group == firstUnstagedGroup {
                Button("Stage All") { Task { await store.stageAll() } }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .disabled(store.isBusy)
    }
}

#Preview {
    ChangesView()
        .previewEnvironment()
}
