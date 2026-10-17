import Foundation

package struct ActionCondition: Codable, Hashable, Sendable {
    package var git: String? = nil
    package var simulator: String? = nil
    package var tool: String? = nil
    package var kind: ProjectKind? = nil

    package init(
        git: String? = nil,
        simulator: String? = nil,
        tool: String? = nil,
        kind: ProjectKind? = nil
    ) {
        self.git = git
        self.simulator = simulator
        self.tool = tool
        self.kind = kind
    }
}
