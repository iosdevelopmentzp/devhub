import Foundation
import DevHubDomain
import DevHubUI

enum SimulatorSectionsMapper {
    static let favoritesID = "favorites"
    static let favoritesHint = "Drag a favorite onto another favorite to change the order"

    static func sections(
        from groups: [SimulatorGroup],
        favoriteOrder: [Simulator.ID],
        matches: (Simulator, String) -> Bool,
        row: (Simulator, String) -> SimulatorRowModel
    ) -> [SimulatorSectionModel] {
        let favorites = groups
            .flatMap { group in
                group.simulators
                    .filter { $0.isFavorite && matches($0, group.runtime) }
                    .map { (simulator: $0, runtime: group.runtime) }
            }
            .enumerated()
            .sorted { (FavoriteOrder.rank(of: $0.element.simulator.id, in: favoriteOrder), $0.offset) < (FavoriteOrder.rank(of: $1.element.simulator.id, in: favoriteOrder), $1.offset) }
            .map { row($0.element.simulator, $0.element.runtime) }
        let runtimes = groups.compactMap { group -> SimulatorSectionModel? in
            let rows = group.simulators
                .filter { $0.isFavorite == false && matches($0, group.runtime) }
                .map { row($0, group.runtime) }
            guard rows.isEmpty == false else { return nil }
            return SimulatorSectionModel(
                id: "runtime:\(group.runtime)",
                title: group.runtime,
                systemImage: nil,
                detail: CountText.invariant(rows.count, "devices"),
                rows: rows
            )
        }
        guard favorites.isEmpty == false else { return runtimes }
        let favoritesSection = SimulatorSectionModel(
            id: favoritesID,
            title: "Favorites",
            systemImage: "star.fill",
            detail: CountText.invariant(favorites.count, "devices"),
            rows: favorites
        )
        return [favoritesSection] + runtimes
    }
}
