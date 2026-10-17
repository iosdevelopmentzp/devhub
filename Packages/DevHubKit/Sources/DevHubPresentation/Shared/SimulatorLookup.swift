import Foundation
import DevHubDomain
import DevHubUI

@MainActor
protocol SimulatorLookup: AnyObject {
    var all: [Simulator] { get }
    var installedAppCounts: [Simulator.ID: Int] { get }
    func simulator(id: Simulator.ID) -> Simulator?
}
