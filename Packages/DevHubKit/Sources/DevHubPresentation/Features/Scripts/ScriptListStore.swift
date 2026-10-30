import Foundation
import Observation
import DevHubDomain

@MainActor
@Observable
final class ScriptListStore {
    private(set) var order: [String] = []
    private(set) var favorites: [String] = []

    @ObservationIgnored private let session: ProjectSession
    @ObservationIgnored private let store: any KeyValueStore
    @ObservationIgnored private var subscription: SubscriptionToken?

    init(session: ProjectSession, events: AppEvents, store: any KeyValueStore) {
        self.session = session
        self.store = store
        load()
        subscription = events.subscribe { [weak self] event in
            guard let self else { return }
            guard case .projectChanged = event else { return }
            load()
        }
    }

    func arranged(_ ids: [String]) -> [String] {
        ScriptListOrder.arranged(ids: ids, order: order, favorites: favorites)
    }

    func isFavorite(_ id: String) -> Bool {
        favorites.contains(id)
    }

    func toggleFavorite(_ id: String, among ids: [String]) {
        let result = ScriptListOrder.toggled(arranged(ids), id: id, favorites: favorites)
        favorites = result.favorites
        save(order: result.order)
    }

    func move(_ id: String, onto target: String, among ids: [String]) {
        save(order: ScriptListOrder.moved(arranged(ids), id: id, onto: target, favorites: favorites))
    }

    func shift(_ id: String, by offset: Int, among ids: [String]) {
        save(order: ScriptListOrder.shifted(arranged(ids), id: id, by: offset, favorites: favorites))
    }

    private func save(order updated: [String]) {
        let missing = order.filter { updated.contains($0) == false }
        order = updated + missing
        store.set(order, forKey: orderKey)
        store.set(favorites, forKey: favoritesKey)
    }

    private func load() {
        order = store.strings(forKey: orderKey) ?? []
        favorites = store.strings(forKey: favoritesKey) ?? []
    }

    private var orderKey: String {
        "scripts.order.\(session.selectedProjectID)"
    }

    private var favoritesKey: String {
        "scripts.favorites.\(session.selectedProjectID)"
    }
}
