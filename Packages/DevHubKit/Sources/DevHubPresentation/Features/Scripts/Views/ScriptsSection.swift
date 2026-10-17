import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptsSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ScriptsStore.self) private var store
    @Environment(SettingsStore.self) private var settings

    @State private var showsHint = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Scripts") {
                HStack(spacing: 6) {
                    Text(settings.values.scriptsFolder)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(settings.values.scriptsFolder)
                    IconButton(systemImage: "lightbulb", help: "How to add your own script") {
                        showsHint.toggle()
                    }
                    IconButton(systemImage: "arrow.up.forward.square", help: "Open the scripts folder") {}
                    IconButton(systemImage: "plus", help: "New script") {}
                }
            }
            if showsHint || store.scripts.isEmpty {
                ScriptHintCard()
            }
            if scripts.isEmpty {
                if store.scripts.isEmpty == false {
                    Text("No scripts match “\(session.searchText)”")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(scripts) { script in
                        ScriptRow(
                            model: ScriptRowMapper.model(
                                for: script,
                                isRunning: store.isRunning(script.id),
                                editor: settings.values.editor
                            )
                        ) {
                            store.run(script)
                        }
                        if script.id != scripts.last?.id {
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

    private var scripts: [ScriptAction] {
        store.scripts.filter { session.matchesSearch($0.title, $0.subtitle, $0.fileName) }
    }
}

#Preview {
    ScrollView {
        ScriptsSection()
            .padding(14)
    }
    .previewEnvironment()
}
