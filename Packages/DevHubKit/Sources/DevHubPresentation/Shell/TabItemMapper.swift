import DevHubDomain
import DevHubUI

enum TabItemMapper {
    static let customIcon = "square.grid.2x2"

    static func items(customTabs: [TabConfig], words: CodeHostWords) -> [TabItem] {
        FeatureRegistry.tabBarFeatures.map { item(for: $0, words: words) } + customTabs.map(item(for:))
    }

    static func item(for selection: TabID, customTabs: [TabConfig], words: CodeHostWords) -> TabItem {
        switch selection {
        case .feature(let id):
            return item(for: FeatureRegistry.feature(id), words: words)
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
