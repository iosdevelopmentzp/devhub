import Foundation
import DevHubDomain
import DevHubUI

enum SimulatorSectionsMapper {

    static func sections(
        from groups: [SimulatorGroup],
        matches: (Simulator, String) -> Bool,
        row: (Simulator, String) -> SimulatorRowModel
    ) -> [SimulatorSectionModel] {
        let favorites = groups.flatMap { group in
            group.simulators
                .filter { $0.isFavorite && matches($0, group.runtime) }
                .map { row($0, group.runtime) }
        }
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
            id: "favorites",
            title: "Favorites",
            systemImage: "star.fill",
            detail: CountText.invariant(favorites.count, "devices"),
            rows: favorites
        )
        return [favoritesSection] + runtimes
    }
}
