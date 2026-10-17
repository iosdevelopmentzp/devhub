import Foundation

package struct SimulatorGroup: Identifiable, Hashable, Sendable {
    package var id: String { runtime }
    package var runtime: String
    package var simulators: [Simulator]

    package init(runtime: String, simulators: [Simulator]) {
        self.runtime = runtime
        self.simulators = simulators
    }
}
