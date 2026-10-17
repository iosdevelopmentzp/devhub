import SwiftUI

struct QuickActionsSection: View {
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ActionRunner.self) private var runner
    @Environment(ProjectSession.self) private var session

    private static let slot = "home.quickActions"

    private var actions: [CatalogAction] {
        catalog.actions(for: .homeQuickActions).filter { session.matchesSearch($0.title, $0.subtitle) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Quick actions")
            if actions.isEmpty {
                emptyText
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], spacing: 8) {
                    ForEach(actions) { action in
                        QuickActionTile(
                            title: action.title,
                            subtitle: action.blockedHint ?? action.subtitle,
                            systemImage: action.systemImage,
                            tint: action.tint,
                            isRunning: runner.isRunning(action)
                        ) {
                            runner.request(action, item: .none, slot: Self.slot)
                        }
                    }
                }
            }
            if let pending = runner.pending(in: Self.slot) {
                promptCard(pending)
            }
            ForEach(actions) { action in
                ActionResultView(action: action)
            }
        }
    }

    private var emptyText: some View {
        Text(session.isSearching ? "No quick action matches the search." : "No quick actions.")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func promptCard(_ pending: PendingRun) -> some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(pending.action.title)
                    .font(.callout.weight(.semibold))
                ActionPrompt(pending: pending)
            }
        }
    }
}

#Preview {
    QuickActionsSection()
        .padding()
        .previewEnvironment()
}
