import Foundation

package struct MockSimulatorSettings: Codable, Hashable, Sendable {
    package var mode: MockMode
    package var setID: MockSet.ID?
    package var upstream: String? = nil

    package init(mode: MockMode, setID: MockSet.ID?, upstream: String? = nil) {
        self.mode = mode
        self.setID = setID
        self.upstream = upstream
    }

    package static let off = MockSimulatorSettings(mode: .off, setID: nil)
}
