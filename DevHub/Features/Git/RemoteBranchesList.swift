import SwiftUI

struct RemoteBranchesList: View {
    @Environment(GitStore.self) private var store
    @Environment(ProjectSession.self) private var session

    private var branches: [RemoteBranch] {
        store.branches.remote.filter { session.matchesSearch($0.name, $0.author, $0.subject) }
    }

    var body: some View {
        if branches.isEmpty {
            ContentUnavailableView.search(text: session.searchText)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(branches) { branch in
                        RemoteBranchRow(branch: branch)
                        Divider().padding(.leading, 56)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    RemoteBranchesList()
        .previewEnvironment()
}
