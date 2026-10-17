import SwiftUI

struct HeaderView: View {
    @Environment(\.panelActions) private var actions
    @Environment(Navigator.self) private var navigator
    @Environment(ProjectSession.self) private var session

    @FocusState private var isSearchFocused: Bool

    private var prompt: String {
        FeatureRegistry.feature(id: navigator.selectedID)?.searchPrompt ?? "Search"
    }

    var body: some View {
        @Bindable var session = session
        HStack(spacing: 10) {
            ProjectMenu()
            Spacer(minLength: 8)
            SearchField(prompt: prompt, text: $session.searchText, focus: $isSearchFocused) {
                actions.handleEscape()
            }
            .frame(width: 260)
            IconButton(systemImage: actions.isPinned ? "pin.fill" : "pin", help: actions.isPinned ? "Unpin the window" : "Pin as a floating window") {
                actions.togglePin()
            }
            IconButton(systemImage: "gearshape", help: "Settings") {
                navigator.show("settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background { dragArea }
        .background(Theme.base)
        .background { searchShortcut }
    }

    @ViewBuilder
    private var dragArea: some View {
        if actions.isPinned == false {
            DragAreaBridge()
        }
    }

    private var searchShortcut: some View {
        Button("Search") { isSearchFocused = true }
            .keyboardShortcut("f", modifiers: .command)
            .opacity(0)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

#Preview {
    HeaderView()
        .previewEnvironment()
}
