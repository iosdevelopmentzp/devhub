import Foundation

package enum ConfigError: LocalizedError, Hashable, Sendable {
    case invalid(String)
    case exampleExists(String)
    case emptyCommand
    case starterExists(String)

    package var errorDescription: String? {
        switch self {
        case let .invalid(message): message
        case let .exampleExists(path): "\(path) already exists. Open it instead, or remove it first."
        case .emptyCommand: "The command is empty. Give run.command at least one word."
        case let .starterExists(path): "\(path) already exists. Edit it, or remove it to create a new one."
        }
    }
}
