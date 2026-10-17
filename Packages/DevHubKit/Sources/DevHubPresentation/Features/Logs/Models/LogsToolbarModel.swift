import Foundation
import DevHubDomain
import DevHubUI

struct LogsToolbarModel: Equatable {
    struct SimulatorOption: Identifiable, Equatable {
        let id: Simulator.ID
        var title: String
    }

    var simulators: [SimulatorOption]
    var canStart: Bool
    var pauseTitle: String
    var canCopy: Bool
    var copyLabel: String
}
