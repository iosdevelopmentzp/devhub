import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class UtilsStore {
    var selection: UtilityID {
        didSet {
            guard selection != oldValue else { return }
            store.set(selection.rawValue, forKey: Keys.selection)
        }
    }

    @ObservationIgnored private let store: any KeyValueStore

    private enum Keys {
        static let selection = "utils.selection"
    }

    init(store: any KeyValueStore) {
        self.store = store
        selection = store.string(forKey: Keys.selection).flatMap(UtilityID.init(rawValue:)) ?? .compressVideo
    }
}
