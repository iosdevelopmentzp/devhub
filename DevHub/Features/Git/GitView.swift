import SwiftUI

struct GitView: View {
    @Environment(GitStore.self) private var store
    @Environment(ProjectSession.self) private var session

    var body: some View {
        VStack(spacing: 0) {
            GitHeaderCard()
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
            GitSegmentBar()
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.surface)
        .task { await store.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if session.hasProject == false {
            EmptyState(systemImage: "arrow.triangle.branch", title: "No project", text: "Add a project in Settings to see its branches.")
        } else if let error = store.error, store.status.isClean, store.branches.local.isEmpty {
            InlineError(text: error) { Task { await store.refresh() } }
            Spacer()
        } else {
            switch store.segment {
            case .local: LocalBranchesList()
            case .remote: RemoteBranchesList()
            case .history: HistoryList()
            case .changes: ChangesView()
            }
        }
    }
}

#Preview {
    GitView()
        .previewEnvironment()
}
