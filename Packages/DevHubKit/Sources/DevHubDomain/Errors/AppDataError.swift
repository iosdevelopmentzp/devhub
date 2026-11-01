import Foundation

package enum AppDataError: LocalizedError, Sendable {
    case notInstalled(String)
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .notInstalled(let bundleID):
            "\(bundleID) is not installed on this simulator. Build & Run the app here first."
        case .command(let message):
            message
        }
    }
}
