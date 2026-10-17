import Foundation
import DevHubDomain
import DevHubUI

enum SimulatorStatusLineMapper {
    static func model(_ status: SimulatorStatus?) -> SimulatorStatusLineModel? {
        guard let status else { return nil }
        return SimulatorStatusLineModel(text: status.text, tint: status.isFailure ? .red : .secondary)
    }
}
