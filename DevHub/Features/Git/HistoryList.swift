import SwiftUI

struct HistoryList: View {
    @Environment(GitStore.self) private var store
    @Environment(ProjectSession.self) private var session

    private var commits: [GitCommit] {
        store.history.filter { session.matchesSearch($0.subject, $0.author, $0.hash) }
    }

    var body: some View {
        if store.history.isEmpty {
            EmptyState(systemImage: "clock", title: "No commits", text: "This checkout has no history yet.")
        } else if commits.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(commits) { commit in
                        CommitRow(commit: commit)
                        Divider().padding(.leading, 14)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    HistoryList()
        .previewEnvironment()
}
