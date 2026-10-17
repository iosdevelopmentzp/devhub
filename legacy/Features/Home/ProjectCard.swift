import SwiftUI

struct ProjectCard: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(SettingsStore.self) private var settings
    @Environment(HomeStore.self) private var store

    private var path: String { session.project?.path ?? "" }

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    IconTile(systemImage: "cube", tint: .indigo, size: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(config.effective?.name ?? session.project?.name ?? "")
                            .font(.headline)
                            .lineLimit(1)
                        Text(path)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .copyOnClick(path, label: "path")
                        tags
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                ActionBar(items: buttons)
            }
        }
    }

    private var buttons: [ActionItem] {
        [
            ActionItem("Finder", systemImage: "folder", hint: "Show the project folder in Finder", priority: 1, isDisabled: false) { store.revealInFinder() },
            ActionItem(settings.editor.title, systemImage: "hammer", hint: "Open the project in \(settings.editor.title)", priority: 3, isDisabled: false) { store.openInEditor() },
            ActionItem(settings.terminal.title, systemImage: "terminal", hint: "Open \(settings.terminal.title) in the project folder", priority: 2, isDisabled: false) { store.openTerminal() },
            ActionItem("Repository", systemImage: "safari", hint: "Open the repository web page", priority: 4, isDisabled: session.repository == nil) { store.openRepository() }
        ]
    }

    private var tags: some View {
        FlowLayout(spacing: 6, lineSpacing: 4) {
            if let branch = session.branch {
                Tag(branch, tint: .blue, systemImage: "arrow.triangle.branch")
                if session.summary.isClean {
                    Tag("clean", tint: .green, systemImage: "checkmark")
                } else {
                    Tag(session.summary.changesText, tint: .orange)
                }
                if session.summary.ahead > 0 {
                    Tag("\(session.summary.ahead) ahead", tint: .green, systemImage: "arrow.up")
                }
                if session.summary.behind > 0 {
                    Tag("\(session.summary.behind) behind", tint: .orange, systemImage: "arrow.down")
                }
            } else {
                Tag("not a git repository", tint: .gray)
            }
            if let kind = session.detection?.kindTitle {
                Tag(kind, tint: .gray)
            }
        }
    }
}

#Preview {
    ProjectCard()
        .padding()
        .previewEnvironment()
}
