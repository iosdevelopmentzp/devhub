import SwiftUI

struct SettingsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(SettingsStore.self) private var settings
    @Environment(SettingsTabStore.self) private var store

    var body: some View {
        @Bindable var settings = settings
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if session.matchesSearch("general", "shortcut", "dock", "terminal", "editor", "usage") {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader("General")
                        PanelCard {
                            VStack(alignment: .leading, spacing: 10) {
                                SettingsPickerRow(title: "Global shortcut", selection: $settings.hotKey, options: HotKeyChoice.allCases, label: \.title)
                                SettingsPickerRow(title: "Terminal", selection: $settings.terminal, options: TerminalApp.allCases, label: \.title)
                                SettingsPickerRow(title: "Editor", selection: $settings.editor, options: EditorApp.allCases, label: \.title)
                                Toggle("Show a Dock icon", isOn: $settings.showDockIcon)
                                Toggle("Show the usage strip", isOn: $settings.showUsageStrip)
                                Toggle("Show Claude session usage in the menu bar", isOn: $settings.showClaudeUsageInMenuBar)
                                Toggle("Show Copilot premium usage in the menu bar", isOn: $settings.showCopilotUsageInMenuBar)
                            }
                        }
                    }
                }
                if session.matchesSearch("projects", "project", "detect", "scheme") || session.projects.contains(where: { session.matchesSearch($0.name, $0.path) }) {
                    ProjectsSection()
                }
                if session.matchesSearch("config", "folder") {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader("Global config folder")
                        PanelCard {
                            HStack {
                                Text(store.globalConfigPath)
                                    .font(.caption.monospaced())
                                    .copyOnClick(store.globalConfigPath, label: "path")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button("Reveal") { store.revealGlobalConfig() }
                                    .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
        .background(Theme.base)
    }
}

#Preview {
    SettingsView()
        .previewEnvironment()
}
