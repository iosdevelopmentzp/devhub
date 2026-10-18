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
            store.set(selection.rawValue, forKey: Self.selectionKey)
        }
    }

    var isPaletteOpen = false
    var paletteQuery = ""

    @ObservationIgnored private let store: any KeyValueStore

    private static let selectionKey = "navigator.selection"

    init(store: any KeyValueStore) {
        self.store = store
        let stored = store.string(forKey: Self.selectionKey)
        selection = stored.flatMap(TabID.init(rawValue:)) ?? .feature(FeatureRegistry.defaultFeatureID)
    }

    func show(_ id: FeatureID) {
        selection = .feature(id)
    }

    func show(tab id: String) {
        selection = .custom(id)
    }

    func togglePalette() {
        paletteQuery = ""
        isPaletteOpen.toggle()
    }
}
