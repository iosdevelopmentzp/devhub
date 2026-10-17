import Foundation

package struct CommandConfig: Codable, Hashable, Sendable {
    package var command: String? = nil

    package init(
        command: String? = nil
    ) {
        self.command = command
    }
}
