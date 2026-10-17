import Foundation
import Observation
import DevHubDomain
import DevHubUI

@MainActor
@Observable
final class OutputPanelState {
    var isVisible: Bool {
        didSet { store.set(isVisible, forKey: Keys.visible) }
    }
    var showsReads: Bool {
        didSet { store.set(showsReads, forKey: Keys.showsReads) }
    }

    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(store: any KeyValueStore, events: AppEvents) {
        self.store = store
        isVisible = store.bool(forKey: Keys.visible)
        showsReads = store.bool(forKey: Keys.showsReads)
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .commandFailed = event else { return }
            isVisible = true
        }
    }

    private enum Keys {
        static let visible = "output.visible"
        static let showsReads = "output.showsReads"
    }
}
