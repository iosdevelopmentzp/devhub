import Foundation

package struct SimulatorsConfig: Codable, Hashable, Sendable {
    package var statusScript: String? = nil

    package init(
        statusScript: String? = nil
    ) {
        self.statusScript = statusScript
    }
}
