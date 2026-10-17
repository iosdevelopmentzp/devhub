import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptsSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(ConfigActionsStore.self) private var store
    @Environment(SettingsStore.self) private var settings
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster

    @State private var showsHint = false

    var body: some View {
        let all = store.actions(for: .homeScripts).compactMap(\.resolved)
        let shown = all.filter { session.matchesSearch($0.config.title, $0.config.subtitle ?? "", $0.origin.fileName) }
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Scripts") {
                HStack(spacing: 6) {
                    if let folder = scriptsFolder {
                        Text(folder.abbreviatingHome)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .hintWhenTruncated(folder)
                    }
                    IconButton(systemImage: "lightbulb", help: "How to add your own script") {
                        showsHint.toggle()
                    }
                    IconButton(systemImage: "arrow.up.forward.square", help: "Open the .devhub folder") {
                        revealFolder()
                    }
                }
            }
            if showsHint || all.isEmpty {
                ScriptHintCard()
            }
            if shown.isEmpty {
                if all.isEmpty == false {
                    Text("No scripts match “\(session.searchText)”")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(shown) { action in
                        ScriptRow(
                            model: ScriptRowMapper.model(for: action, isRunning: store.isRunning(action.id), lastRun: store.lastRun(of: action.id), editor: settings.values.editor),
                            onRun: { store.request(action, item: .none, slot: slot(action)) },
                            onStop: { store.stop(action.id) },
                            onEdit: { path in appActions.openInEditor(path: path, editor: settings.values.editor) },
                            onReveal: { path in appActions.openInFinder(path: path) }
                        ) {
                            if let pending = store.pending(in: slot(action)) {
                                ConfigActionPrompt(pending: pending)
                            }
                            ConfigActionResultView(action: action)
                        }
                        if action.id != shown.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Theme.surface)
                        .shadow(color: Theme.shadow, radius: 3, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Theme.border)
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .animation(.snappy(duration: 0.18), value: showsHint)
    }

    private var scriptsFolder: String? {
        let preferred: [ConfigLayer] = [.project, .user, .global]
        return preferred.lazy
            .compactMap { layer in config.resolved.layers.first { $0.layer == layer && $0.exists } }
            .first
            .map { $0.directory + "/scripts" }
    }

    private func slot(_ action: ResolvedAction) -> String {
        "home.scripts:\(action.id)"
    }

    private func revealFolder() {
        Task {
            guard let folder = await config.existingFolder() else {
                toaster.show("No .devhub folder yet. Create the example in Settings.")
                return
            }
            appActions.openInFinder(path: folder)
        }
    }
}

#Preview {
    ScrollView {
        ScriptsSection()
            .padding(14)
    }
    .previewEnvironment()
}
