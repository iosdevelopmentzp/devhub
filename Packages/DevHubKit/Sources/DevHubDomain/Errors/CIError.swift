import Foundation

package enum CIError: LocalizedError, Equatable, Sendable {
    case notInstalled
    case oldVersion(found: String)
    case notLoggedIn
    case rateLimited
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .notInstalled:
            "The circleci tool is not installed. Run: brew install circleci && circleci auth login"
        case .oldVersion(let found):
            "The circleci tool is version \(found). DevHub needs 1.0 or newer. Run: brew upgrade circleci"
        case .notLoggedIn:
            "The circleci tool is not logged in. Run: circleci auth login"
        case .rateLimited:
            "CircleCI limits the requests for a while (429). DevHub waits before the next read."
        case .command(let message):
            message
        }
    }
}
