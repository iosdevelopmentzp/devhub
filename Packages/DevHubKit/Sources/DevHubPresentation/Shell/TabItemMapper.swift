import DevHubDomain
import DevHubUI

enum TabItemMapper {
    static let customIcon = "square.grid.2x2"

    static func items(in placement: TabPlacement, layout: TabLayout, customTabs: [TabConfig], words: CodeHostWords) -> [TabItem] {
        layout.tabs(in: placement, customTabs: customTabs).map { item(for: $0, customTabs: customTabs, words: words) }
    }

    static func allItems(layout: TabLayout, customTabs: [TabConfig], words: CodeHostWords) -> [TabItem] {
        items(in: .bar, layout: layout, customTabs: customTabs, words: words) + items(in: .utils, layout: layout, customTabs: customTabs, words: words)
    }

    static func item(for selection: TabID, customTabs: [TabConfig], words: CodeHostWords) -> TabItem {
        switch selection {
        case .feature(let id):
            return item(for: FeatureRegistry.feature(id), words: words)
        case .utility(let id):
            return TabItem(id: .utility(id), title: id.title, systemImage: id.systemImage, searchPrompt: id.searchPrompt)
        case .custom(let id):
            guard let tab = customTabs.first(where: { $0.id == id }) else {
                return item(for: FeatureRegistry.feature(FeatureRegistry.defaultFeatureID), words: words)
            }
            return item(for: tab)
        }
    }

    static func item(for tab: TabConfig) -> TabItem {
        TabItem(
            id: .custom(tab.id),
            title: tab.title,
            systemImage: tab.icon ?? customIcon,
            searchPrompt: tab.searchPrompt ?? "Search \(tab.title)"
        )
    }

    private static func item(for feature: Feature, words: CodeHostWords) -> TabItem {
        TabItem(id: .feature(feature.id), title: feature.title(words), systemImage: feature.systemImage, searchPrompt: feature.searchPrompt(words))
    }
}
