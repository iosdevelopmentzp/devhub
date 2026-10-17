import Foundation
import DevHubDomain
import DevHubUI

struct NetworkToolbarModel: Equatable {
    struct SimulatorOption: Identifiable, Equatable {
        let id: Simulator.ID
        var title: String
    }

    struct FilterOption: Identifiable, Equatable {
        let id: NetworkRequestFilter
        var title: String
    }

    var simulators: [SimulatorOption]
    var filters: [FilterOption]
    var pauseTitle: String
    var countText: String
    var canClear: Bool
}
