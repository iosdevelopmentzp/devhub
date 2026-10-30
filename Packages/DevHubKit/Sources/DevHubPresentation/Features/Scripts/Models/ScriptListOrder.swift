import Foundation

enum ScriptListOrder {

    static func arranged(ids: [String], order: [String], favorites: [String]) -> [String] {
        let ranked = ids.enumerated().sorted { lhs, rhs in
            (FavoriteOrder.rank(of: lhs.element, in: order), lhs.offset) < (FavoriteOrder.rank(of: rhs.element, in: order), rhs.offset)
        }
        .map(\.element)
        return ranked.filter { favorites.contains($0) } + ranked.filter { favorites.contains($0) == false }
    }

    static func moved(_ arranged: [String], id: String, onto target: String, favorites: [String]) -> [String] {
        guard favorites.contains(id) == favorites.contains(target) else { return arranged }
        return FavoriteOrder.moved(arranged, id: id, onto: target)
    }

    static func shifted(_ arranged: [String], id: String, by offset: Int, favorites: [String]) -> [String] {
        guard let index = arranged.firstIndex(of: id), arranged.indices.contains(index + offset) else { return arranged }
        return moved(arranged, id: id, onto: arranged[index + offset], favorites: favorites)
    }

    static func toggled(_ arranged: [String], id: String, favorites: [String]) -> (order: [String], favorites: [String]) {
        guard arranged.contains(id) else { return (arranged, favorites) }
        let updated = favorites.contains(id) ? favorites.filter { $0 != id } : favorites + [id]
        var order = arranged.filter { $0 != id }
        let lastFavorite = order.lastIndex { updated.contains($0) }
        order.insert(id, at: lastFavorite.map { $0 + 1 } ?? 0)
        return (order, updated)
    }
}
