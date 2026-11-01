import Foundation

package enum DiskCleanupError: LocalizedError, Sendable {
    case notAllowed(String)
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .notAllowed(let path):
            "DevHub deletes only inside DerivedData, ~/Library/Developer/Xcode and ~/Library/Caches. Not deleted: \(path)"
        case .command(let message):
            message
        }
    }
}
