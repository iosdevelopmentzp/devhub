import Foundation

package struct AIConfig: Codable, Hashable, Sendable {
    package var reviewCommand: String? = nil
    package var commands: [String: String]? = nil
    package var textCommands: [String: String]? = nil

    package init(reviewCommand: String? = nil, commands: [String: String]? = nil, textCommands: [String: String]? = nil) {
        self.reviewCommand = reviewCommand
        self.commands = commands
        self.textCommands = textCommands
    }
}
