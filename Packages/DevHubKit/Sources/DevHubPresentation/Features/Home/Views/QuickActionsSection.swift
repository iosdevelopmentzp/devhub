import SwiftUI
import DevHubDomain
import DevHubUI

struct QuickActionsSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigActionsStore.self) private var store
    @Environment(BuildStore.self) private var build
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    private static let slot = "home.quickActions"

    var body: some View {
        let tiles = models
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Quick actions") {
                TabSearchField()
            }
            if tiles.isEmpty {
                Text("No actions match “\(session.searchText)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 8) {
                    ForEach(tiles) { tile in
                        QuickActionTile(model: tile) {
                            perform(tile.id)
                        }
                    }
                }
            }
            ConfigActionResults(placement: .homeQuickActions, slot: Self.slot)
        }
    }

    private var models: [QuickActionTileModel] {
        let branch = store.currentBranch
        let effective = store.effective
        return store.actions(for: .homeQuickActions)
            .map { QuickActionTileMapper.model(for: $0, scheme: effective.scheme, branch: branch, words: words, isBuildRunning: build.isRunning, isRunning: store.isRunning($0.id)) }
            .filter { session.matchesSearch($0.title, $0.subtitle) }
    }

    private func perform(_ id: String) {
        switch store.actions(for: .homeQuickActions).first(where: { $0.id == id }) {
        case let .builtin(builtin):
            appActions.perform(builtin)
        case let .config(action):
            store.request(action, item: .none, slot: Self.slot)
        case nil:
            break
        }
    }
}

#Preview {
    QuickActionsSection()
        .padding()
        .previewEnvironment()
}
