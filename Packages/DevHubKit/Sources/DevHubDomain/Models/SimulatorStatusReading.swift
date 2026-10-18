import Foundation

package struct SimulatorStatusReading: Hashable, Sendable {
    package var line: String?
    package var state: AppStateReport?

    package init(line: String?, state: AppStateReport?) {
        self.line = line
        self.state = state
    }
}
