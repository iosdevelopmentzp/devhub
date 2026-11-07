import SwiftUI
import DevHubDomain
import DevHubUI

struct UtilsView: View {
    @Environment(Navigator.self) private var navigator
    @Environment(ConfigStore.self) private var config
    @Environment(\.codeHostWords) private var words

    var body: some View {
        let tab = navigator.utilsTab
        VStack(spacing: 0) {
            UtilsTabBar(items: TabItemMapper.items(in: .utils, layout: navigator.layout, customTabs: config.resolved.tabs, words: words), selection: tab, showsSearch: isUtility(tab)) {
                navigator.utilsSelection = $0
            }
            Divider()
            content(for: tab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
    }

    private func isUtility(_ tab: TabID?) -> Bool {
        guard case .utility = tab else { return false }
        return true
    }

    @ViewBuilder
    private func content(for tab: TabID?) -> some View {
        switch tab {
        case .feature(let id):
            FeatureRegistry.feature(id).makeView()
        case .utility(let id):
            UtilityContent(id: id)
        case .custom(let id):
            if let custom = config.resolved.tabs.first(where: { $0.id == id }) {
                CustomTabView(tab: custom)
            } else {
                message(ListMessage("This tab is gone", systemImage: "square.grid.2x2", description: "Its file was removed from the .devhub folders."))
            }
        case nil:
            message(ListMessage("Nothing in Utils", systemImage: "hammer", description: "Right-click a tab in the tab bar and choose Move to Utils."))
        }
    }
}

extension UtilsView {
    private func message(_ message: ListMessage) -> some View {
        ListState(failure: nil, isLoading: false, loadingTitle: "", empty: message, noResultsFor: nil) {
            EmptyView()
        }
    }
}

#Preview {
    UtilsView()
        .previewEnvironment()
}
