import Foundation

package enum AppLaunchError: LocalizedError, Sendable {
    case command(String)
    case noAppToReinstall

    package var errorDescription: String? {
        switch self {
        case .command(let message):
            message
        case .noAppToReinstall:
            "No app bundle to reinstall from. Build the project once (Build & Run) and try again."
        }
    }
}
