import SwiftUI
import DevHubDomain
import DevHubUI

struct TabSearchField: View {
    @Environment(ProjectSession.self) private var session
    @Environment(Navigator.self) private var navigator
    @Environment(ConfigStore.self) private var config
    @Environment(\.codeHostWords) private var words
    @FocusState private var isFocused: Bool

    private var prompt: String? {
        TabItemMapper.item(for: navigator.currentTab, customTabs: config.resolved.tabs, words: words).searchPrompt
    }

    var body: some View {
        @Bindable var session = session
        if let prompt {
            SearchField(prompt: prompt, text: $session.searchText, focus: $isFocused)
                .frame(minWidth: 120, maxWidth: 200)
                .layoutPriority(1)
                .hint("\(prompt) (⌘F). Esc clears.")
                .background(
                    Button("") { isFocused = true }
                        .keyboardShortcut("f", modifiers: .command)
                        .opacity(0)
                        .allowsHitTesting(false)
                )
        }
    }
}

#Preview {
    TabSearchField()
        .padding()
        .previewEnvironment()
}
