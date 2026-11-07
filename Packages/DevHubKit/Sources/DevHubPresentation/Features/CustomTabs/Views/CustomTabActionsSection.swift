import SwiftUI
import DevHubDomain
import DevHubUI

struct CustomTabActionsSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigActionsStore.self) private var store
    @Environment(SettingsStore.self) private var settings
    @Environment(AppActions.self) private var appActions
    @Environment(BuildStore.self) private var build
    @Environment(\.codeHostWords) private var words

    let title: String
    let actions: [CatalogAction]
    let missing: [String]
    let slot: String
    let item: ActionItemContext

    var body: some View {
        let shown = actions.filter(matches)
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title) {}
            ForEach(missing, id: \.self) { id in
                Label("Unknown action \(id)", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Tint.red.color)
            }
            if shown.isEmpty, actions.isEmpty == false {
                Text("No actions match “\(session.searchText)”")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            PanelCard {
                VStack(spacing: 0) {
                    ForEach(shown) { action in
                        row(action)
                        if action.id != shown.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            }
            .opacity(shown.isEmpty ? 0 : 1)
        }
    }

    @ViewBuilder
    private func row(_ action: CatalogAction) -> some View {
        switch action {
        case let .builtin(builtin):
            let tile = tileModel(action)
            Button {
                appActions.perform(builtin)
            } label: {
                HStack(spacing: 10) {
                    IconTile(systemImage: tile.systemImage, tint: tile.tint.color, size: 32)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tile.title)
                            .font(.callout.weight(.medium))
                        Text(tile.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(tile.isEnabled == false)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
        case let .config(resolved):
            ScriptRow(
                model: ScriptRowMapper.model(for: resolved, isRunning: store.isRunning(resolved.id), lastRun: store.lastRun(of: resolved.id), editor: settings.values.editor, isFavorite: false),
                onRun: { store.request(resolved, item: item, slot: rowSlot(resolved)) },
                onStop: { store.stop(resolved.id) },
                onEdit: { path in appActions.openInEditor(path: path, editor: settings.values.editor) },
                onReveal: { path in appActions.openInFinder(path: path) },
                ordering: nil
            ) {
                if let pending = store.pending(in: rowSlot(resolved)) {
                    ConfigActionPrompt(pending: pending)
                }
                ConfigActionResultView(action: resolved)
            }
        }
    }

    private func tileModel(_ action: CatalogAction) -> QuickActionTileModel {
        QuickActionTileMapper.model(for: action, scheme: store.effective.scheme, branch: store.currentBranch, words: words, isBuildRunning: build.isRunning, isRunning: false)
    }

    private func rowSlot(_ action: ResolvedAction) -> String {
        "\(slot):\(action.id)"
    }

    private func matches(_ action: CatalogAction) -> Bool {
        switch action {
        case .builtin:
            session.matchesSearch(tileModel(action).title)
        case let .config(resolved):
            session.matchesSearch(resolved.config.title, resolved.config.subtitle ?? "")
        }
    }
}

#Preview {
    CustomTabActionsSection(title: "Project", actions: [], missing: ["old-action"], slot: "preview", item: .none)
        .padding()
        .previewEnvironment()
}
