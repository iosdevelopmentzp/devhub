import Foundation

package enum AITextError: LocalizedError, Sendable, Equatable {
    case notInstalled(String)
    case command(String)
    case emptyAnswer
    case nothingToDescribe

    package var errorDescription: String? {
        switch self {
        case .notInstalled(let tool):
            "\(tool) was not found. Install it, or set its command in ai.textCommands of .devhub/project.json."
        case .command(let message):
            message
        case .emptyAnswer:
            "The AI tool returned no text. Try again or choose the other tool."
        case .nothingToDescribe:
            "There are no changes to describe."
        }
    }
}
