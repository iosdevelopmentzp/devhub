import SwiftUI

struct LocalBranchesList: View {
    @Environment(GitStore.self) private var store
    @Environment(ProjectSession.self) private var session

    private var branches: [GitBranch] {
        let current = store.currentBranch
        return store.branches.local
            .filter { session.matchesSearch($0.name, $0.subject) }
            .sorted { ($0.name == current) && ($1.name != current) }
    }

    var body: some View {
        if branches.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(branches) { branch in
                        LocalBranchRow(branch: branch)
                        if branch.id != branches.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    LocalBranchesList()
        .previewEnvironment()
}
