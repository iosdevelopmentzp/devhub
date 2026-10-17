import Foundation

package enum LogTargetPolicy {

    package static func defaultSimulator(target: Simulator?, simulators: [Simulator]) -> Simulator? {
        if let target, target.state == .booted {
            return target
        }
        return simulators.first { $0.state == .booted }
    }
}
