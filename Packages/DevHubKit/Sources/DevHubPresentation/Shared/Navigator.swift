import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class Navigator {
    var selection: TabID {
        didSet {
            guard selection != oldValue else { return }
            store.set(selection.rawValue, forKey: Keys.selection)
        }
    }

    var utilsSelection: TabID {
        didSet {
            guard utilsSelection != oldValue else { return }
            store.set(utilsSelection.rawValue, forKey: Keys.utilsSelection)
        }
    }

    private(set) var layout: TabLayout {
        didSet {
            guard layout != oldValue else { return }
            store.set(layout.rawOverrides, forKey: Keys.layout)
            store.set(layout.rawOrder, forKey: Keys.order)
        }
    }

    var isPaletteOpen = false
    var paletteQuery = ""

    @ObservationIgnored var draggedTab: TabID?
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private let customTabs: any CustomTabLookup

    private enum Keys {
        static let selection = "navigator.selection"
        static let utilsSelection = "utils.selection"
        static let layout = "tabs.layout"
        static let order = "tabs.order"
    }

    init(store: any KeyValueStore, customTabs: any CustomTabLookup) {
        self.store = store
        self.customTabs = customTabs
        selection = store.string(forKey: Keys.selection).flatMap(TabID.init(rawValue:)) ?? .feature(FeatureRegistry.defaultFeatureID)
        utilsSelection = Self.savedUtilsSelection(in: store) ?? .utility(.compressVideo)
        layout = TabLayout(rawOverrides: store.stringMap(forKey: Keys.layout) ?? [:], rawOrder: store.strings(forKey: Keys.order) ?? [])
    }

    var currentTab: TabID {
        guard selection == .feature(.utils) else { return selection }
        return utilsTab ?? selection
    }

    var utilsTab: TabID? {
        let tabs = tabs(in: .utils)
        return tabs.contains(utilsSelection) ? utilsSelection : tabs.first
    }

    func tabs(in placement: TabPlacement) -> [TabID] {
        layout.tabs(in: placement, customTabs: customTabs.customTabs)
    }

    func placement(of tab: TabID) -> TabPlacement {
        layout.placement(of: tab, customTabs: customTabs.customTabs)
    }

    func canMove(_ tab: TabID) -> Bool {
        layout.canMove(tab)
    }

    func show(_ tab: TabID) {
        switch placement(of: tab) {
        case .bar:
            selection = tab
        case .utils:
            utilsSelection = tab
            selection = .feature(.utils)
        }
    }

    func show(_ id: FeatureID) {
        show(.feature(id))
    }

    func show(tab id: String) {
        show(.custom(id))
    }

    func move(_ tab: TabID, to placement: TabPlacement) {
        guard canMove(tab) else { return }
        let wasOnScreen = currentTab == tab
        layout = layout.moving(tab, to: placement, customTabs: customTabs.customTabs)
        guard wasOnScreen else { return }
        show(tab)
    }

    func reorder(_ tab: TabID, to target: TabID) {
        let wasOnScreen = currentTab == tab
        let moved = layout.reordering(tab, to: target, customTabs: customTabs.customTabs)
        guard moved != layout else { return }
        layout = moved
        guard wasOnScreen else { return }
        show(tab)
    }

    func resetTabOrder() {
        layout = layout.resettingOrder()
    }

    func togglePalette() {
        paletteQuery = ""
        isPaletteOpen.toggle()
    }

    private static func savedUtilsSelection(in store: any KeyValueStore) -> TabID? {
        guard let saved = store.string(forKey: Keys.utilsSelection) else { return nil }
        if let tab = TabID(rawValue: saved) { return tab }
        return UtilityID(rawValue: saved).map(TabID.utility)
    }
}
