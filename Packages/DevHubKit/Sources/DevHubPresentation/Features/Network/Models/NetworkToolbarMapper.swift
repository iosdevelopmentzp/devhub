import Foundation
import DevHubDomain
import DevHubUI

enum NetworkToolbarMapper {

    static func model(
        simulators: [Simulator],
        runtime: (Simulator.ID) -> String?,
        isPaused: Bool,
        pendingCount: Int,
        shownCount: Int,
        totalCount: Int
    ) -> NetworkToolbarModel {
        NetworkToolbarModel(
            simulators: simulators
                .filter { $0.state == .booted }
                .map { NetworkToolbarModel.SimulatorOption(id: $0.id, title: "\($0.name) · \(runtime($0.id) ?? "")") },
            filters: NetworkRequestFilter.allCases.map { NetworkToolbarModel.FilterOption(id: $0, title: title(for: $0)) },
            pauseTitle: isPaused && pendingCount > 0 ? "Paused · \(pendingCount) new" : "Pause",
            countText: shownCount == totalCount
                ? CountText.invariant(totalCount, "requests")
                : "\(shownCount) of \(CountText.invariant(totalCount, "requests"))",
            canClear: totalCount > 0 || pendingCount > 0
        )
    }

    static func title(for filter: NetworkRequestFilter) -> String {
        switch filter {
        case .all: "All"
        case .failed: "Failed"
        case .slow: "Slow"
        }
    }
}
