import SwiftUI

struct ScriptsSection: View {
    @Environment(ActionCatalog.self) private var catalog
    @Environment(ConfigStore.self) private var config
    @Environment(ProjectSession.self) private var session
    @Environment(HomeStore.self) private var store

    @State private var showsHint = false

    private var actions: [CatalogAction] {
        catalog.actions(for: .homeScripts).filter {
            session.matchesSearch($0.title, $0.subtitle, $0.fileName ?? "")
        }
    }

    private var folder: String? {
        config.scriptsFolder().map { ($0 as NSString).abbreviatingWithTildeInPath }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Scripts") {
                HStack(spacing: 4) {
                    folderButton
                    IconButton(systemImage: "lightbulb", help: "How to write a script") { showsHint.toggle() }
                        .popover(isPresented: $showsHint, arrowEdge: .bottom) { ScriptHeaderHint() }
                    IconButton(systemImage: "arrow.clockwise", help: "Reload scripts and config") { store.reloadConfig() }
                }
            }
            PanelCard {
                if actions.isEmpty {
                    Text(emptyText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(actions) { action in
                            ScriptRow(action: action)
                            if action.id != actions.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyText: String {
        if session.isSearching {
            return "No script matches the search."
        }
        return "No scripts yet. Put executable files with a # devhub: header into a scripts folder of .devhub."
    }

    @ViewBuilder
    private var folderButton: some View {
        if let folder {
            Button { store.revealScriptsFolder() } label: {
                Text(folder)
                    .font(.caption.monospaced())
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 260)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .hint("Show the scripts folder in Finder")
        }
    }
}

#Preview {
    ScriptsSection()
        .padding()
        .previewEnvironment()
}
