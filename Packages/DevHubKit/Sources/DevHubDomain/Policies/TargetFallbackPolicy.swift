import Foundation

package enum TargetFallbackPolicy {

    package static func target(among simulators: [Simulator]) -> Simulator? {
        simulators.first { $0.state == .booted && $0.isPhysical == false }
            ?? simulators.first { $0.isPhysical == false }
            ?? simulators.first { $0.state == .booted }
            ?? simulators.first
    }
}
