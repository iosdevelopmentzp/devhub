import Foundation
import DevHubDomain
import DevHubUI

enum SimulatorsToolbarText {
    static func count(simulators: [Simulator]) -> String {
        let devices = simulators.filter(\.isPhysical).count
        let text = CountText.invariant(simulators.count - devices, "simulators")
        guard devices > 0 else { return text }
        return "\(text) · \(CountText.invariant(devices, "devices"))"
    }
}
