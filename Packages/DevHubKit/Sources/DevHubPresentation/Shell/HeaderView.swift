import SwiftUI
import DevHubDomain
import DevHubUI

struct HeaderView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(Navigator.self) private var navigator
    @Environment(AppActions.self) private var appActions
    @Environment(ConfigStore.self) private var config
    @Environment(SettingsStore.self) private var settings
    @Environment(\.isPinnedWindow) private var isPinnedWindow
    @Environment(\.togglePin) private var togglePin
    @Environment(\.codeHostWords) private var words
    @FocusState private var isSearchFocused: Bool

    private var searchPrompt: String? {
        TabItemMapper.item(for: navigator.selection, customTabs: config.resolved.tabs, words: words).searchPrompt
    }

    var body: some View {
        @Bindable var session = session
        HStack(spacing: 10) {
            ProjectMenu()
            Spacer(minLength: 8)
            if let searchPrompt {
                SearchField(prompt: searchPrompt, text: $session.searchText, focus: $isSearchFocused)
                    .frame(width: 260)
                    .hint("\(searchPrompt) on this tab (⌘F). Esc clears.")
                    .background(
                        Button("") { isSearchFocused = true }
                            .keyboardShortcut("f", modifiers: .command)
                            .opacity(0)
                            .allowsHitTesting(false)
                    )
            }
            IconButton(systemImage: "command", help: "Command palette (⌘K): tabs, actions, branches, simulators, worktrees, requests, sessions") {
                navigator.togglePalette()
            }
            .keyboardShortcut("k", modifiers: .command)
            if settings.values.windowMode == .panel {
                IconButton(
                    systemImage: isPinnedWindow ? "pin.fill" : "pin",
                    help: isPinnedWindow ? "Unpin: close this window, use the menu bar panel" : "Pin: keep DevHub open in a floating window",
                    tint: isPinnedWindow ? .accentColor : .primary
                ) {
                    togglePin()
                }
            }
            IconButton(
                systemImage: "gearshape",
                help: "Settings",
                tint: navigator.selection == .feature(.settings) ? .accentColor : .primary
            ) {
                appActions.openSettings()
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(PanelDragArea())
    }

}
