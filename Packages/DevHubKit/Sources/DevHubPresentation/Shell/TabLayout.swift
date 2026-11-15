import DevHubDomain
import DevHubUI

struct TabLayout: Equatable {
    var overrides: [TabID: TabPlacement] = [:]
    var order: [TabID] = []

    static let fixed: Set<TabID> = [.feature(.home), .feature(.utils)]

    init() {}

    init(rawOverrides: [String: String], rawOrder: [String]) {
        for (tab, placement) in rawOverrides {
            guard let tab = TabID(rawValue: tab), let placement = TabPlacement(rawValue: placement) else { continue }
            overrides[tab] = placement
        }
        var seen: Set<TabID> = []
        order = rawOrder.compactMap(TabID.init(rawValue:)).filter { seen.insert($0).inserted }
    }

    var rawOverrides: [String: String] {
        Dictionary(uniqueKeysWithValues: overrides.map { ($0.key.rawValue, $0.value.rawValue) })
    }

    var rawOrder: [String] {
        order.map(\.rawValue)
    }

    var hasCustomOrder: Bool {
        order.isEmpty == false
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

    func moving(_ tab: TabID, to placement: TabPlacement, customTabs: [TabConfig]) -> TabLayout {
        guard canMove(tab) else { return self }
        var layout = self
        layout.overrides[tab] = placement
        guard hasCustomOrder else { return layout }
        let others = layout.tabs(in: placement, customTabs: customTabs).filter { $0 != tab }
        layout.order = others + [tab] + order.filter { others.contains($0) == false && $0 != tab }
        return layout
    }

    func reordering(_ tab: TabID, to target: TabID, customTabs: [TabConfig]) -> TabLayout {
        guard tab != target else { return self }
        let placement = placement(of: target, customTabs: customTabs)
        var layout = self
        let changesPlacement = self.placement(of: tab, customTabs: customTabs) != placement
        if changesPlacement {
            guard canMove(tab) else { return self }
            layout.overrides[tab] = placement
        }
        var tabs = layout.tabs(in: placement, customTabs: customTabs)
        guard let from = tabs.firstIndex(of: tab), let to = tabs.firstIndex(of: target) else { return self }
        tabs.remove(at: from)
        tabs.insert(tab, at: changesPlacement ? (tabs.firstIndex(of: target) ?? to) : to)
        layout.order = tabs + order.filter { tabs.contains($0) == false }
        return layout
    }

    func resettingOrder() -> TabLayout {
        var layout = self
        layout.order = []
        return layout
    }

    func tabs(in placement: TabPlacement, customTabs: [TabConfig]) -> [TabID] {
        let all = FeatureRegistry.tabBarFeatures.map { TabID.feature($0.id) } + UtilityID.allCases.map(TabID.utility) + customTabs.map { TabID.custom($0.id) }
        let placed = all.filter { self.placement(of: $0, customTabs: customTabs) == placement }
        guard hasCustomOrder else { return placed }
        let ranks = Dictionary(uniqueKeysWithValues: order.enumerated().map { ($0.element, $0.offset) })
        return placed.enumerated()
            .sorted { (ranks[$0.element] ?? order.count + $0.offset) < (ranks[$1.element] ?? order.count + $1.offset) }
            .map(\.element)
    }
}
