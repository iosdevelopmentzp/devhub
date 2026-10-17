import SwiftUI

struct AIView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(AIStore.self) private var store

    private var groups: [AIDayGroup] {
        store.groups { session.matchesSearch($0.title, $0.folder, $0.lastPrompt, $0.branch ?? "") }
    }

    var body: some View {
        let groups = groups
        VStack(spacing: 0) {
            AIToolbar(count: groups.reduce(0) { $0 + $1.sessions.count })
            Divider()
            if let error = store.error {
                InlineError(text: error) { Task { await store.refresh() } }
                Spacer()
            } else if groups.isEmpty {
                empty
            } else {
                list(groups)
            }
        }
        .background(Theme.surface)
        .task { await store.refresh() }
    }

    @ViewBuilder
    private var empty: some View {
        if session.isSearching {
            ContentUnavailableView.search(text: session.searchText)
        } else if store.isLoading {
            ProgressView("Reading sessions")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            EmptyState(systemImage: "sparkles", title: "No sessions", text: "Sessions of Copilot and Claude Code for this scope appear here.")
        }
    }

    private func list(_ groups: [AIDayGroup]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(groups) { group in
                    AIDayHeader(title: group.title)
                    ForEach(group.sessions) { item in
                        AISessionRow(session: item)
                        if item.id != group.sessions.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    AIView()
        .previewEnvironment()
}
