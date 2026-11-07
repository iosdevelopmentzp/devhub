import DevHubDomain
import DevHubUI

struct TabLayout: Equatable {
    var overrides: [TabID: TabPlacement] = [:]

    static let fixed: Set<TabID> = [.feature(.home), .feature(.utils)]

    init() {}

    init(rawOverrides: [String: String]) {
        for (tab, placement) in rawOverrides {
            guard let tab = TabID(rawValue: tab), let placement = TabPlacement(rawValue: placement) else { continue }
            overrides[tab] = placement
        }
    }

    var rawOverrides: [String: String] {
        Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value.rawValue) })
    }

    static func defaultPlacement(of tab: TabID, customTabs: [TabConfig]) -> TabPlacement {
        switch tab {
        case .feature: .bar
        case .utility: .utils
        case .custom(let id): customTabs.first { $0.id == id }?.placement ?? .utils
        }
    }

    func placement(of tab: TabID, customTabs: [TabConfig]) -> TabPlacement {
        guard canMove(tab) else { return .bar }
        return overrides[tab] ?? Self.defaultPlacement(of: tab, customTabs: customTabs)
    }

    func canMove(_ tab: TabID) -> Bool {
        switch tab {
        case .feature(let id): Self.fixed.contains(tab) == false && FeatureRegistry.feature(id).showsInTabBar
        case .utility, .custom: true
        }
    }

    func moving(_ tab: TabID, to placement: TabPlacement) -> TabLayout {
        guard canMove(tab) else { return self }
        var layout = self
        layout.overrides[tab] = placement
        return layout
    }

    func tabs(in placement: TabPlacement, customTabs: [TabConfig]) -> [TabID] {
        let all = FeatureRegistry.tabBarFeatures.map { TabID.feature($0.id) } + UtilityID.allCases.map(TabID.utility) + customTabs.map { TabID.custom($0.id) }
        return all.filter { self.placement(of: $0, customTabs: customTabs) == placement }
    }
}
