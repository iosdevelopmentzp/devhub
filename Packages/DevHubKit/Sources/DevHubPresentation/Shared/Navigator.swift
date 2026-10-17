import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class Navigator {
    var selection: FeatureID {
        didSet {
            guard selection != oldValue else { return }
            store.set(selection.rawValue, forKey: Self.selectionKey)
        }
    }

    @ObservationIgnored private let store: any KeyValueStore

    private static let selectionKey = "navigator.selection"

    init(store: any KeyValueStore) {
        self.store = store
        let stored = store.string(forKey: Self.selectionKey)
        selection = stored.flatMap(FeatureID.init(rawValue:)) ?? FeatureRegistry.defaultFeatureID
    }

    func show(_ id: FeatureID) {
        selection = id
    }
}
