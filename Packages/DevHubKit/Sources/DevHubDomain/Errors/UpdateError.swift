import Foundation

package enum UpdateError: LocalizedError, Sendable, Equatable {
    case scriptMissing(String)
    case alreadyRunning
    case git(String)

    package var errorDescription: String? {
        switch self {
        case .scriptMissing(let path):
            "The update script was not found at \(path). Run Scripts/install.sh once from the repository."
        case .alreadyRunning:
            "An update is already running."
        case .git(let message):
            message
        }
    }
}
