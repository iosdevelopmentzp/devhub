import Foundation

package enum ConfigError: LocalizedError, Hashable, Sendable {
    case invalid(String)
    case exampleExists(String)
    case emptyCommand

    package var errorDescription: String? {
        switch self {
        case let .invalid(message): message
        case let .exampleExists(path): "\(path) already exists. Open it instead, or remove it first."
        case .emptyCommand: "The command is empty. Give run.command at least one word."
        }
    }
}
