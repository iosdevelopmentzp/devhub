import SwiftUI

struct WorktreesView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(WorktreesStore.self) private var store

    @State private var showsCreation = false

    private var sections: WorktreeSections {
        WorktreeSections(store.worktrees.filter { session.matchesSearch($0.title, $0.path) })
    }

    var body: some View {
        VStack(spacing: 0) {
            WorktreesToolbar(showsCreation: $showsCreation)
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
        .task { await store.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        let current = sections
        if let error = store.error {
            InlineError(text: error) { Task { await store.refresh() } }
            Spacer()
        } else if session.hasProject == false {
            EmptyState(systemImage: "square.stack.3d.up", title: "No project", text: "Add a project in Settings to see its worktrees.")
        } else if store.worktrees.isEmpty {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                EmptyState(systemImage: "square.stack.3d.up", title: "No worktrees", text: "This folder is not a git repository.")
            }
        } else if session.isSearching, current.main == nil, current.inProgress.isEmpty, current.finished.isEmpty, current.missing.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
        } else {
            list(current)
        }
    }

    private func list(_ current: WorktreeSections) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if showsCreation {
                    NewWorktreeCard(isShown: $showsCreation)
                }
                if let main = current.main {
                    WorktreeSectionView(title: "Main checkout", worktrees: [main])
                }
                WorktreeSectionView(title: "In progress", worktrees: current.inProgress)
                WorktreeSectionView(title: "Finished", worktrees: current.finished)
                WorktreeSectionView(title: "Missing folder", worktrees: current.missing)
            }
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    WorktreesView()
        .previewEnvironment()
}
