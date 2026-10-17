import Foundation

package enum MergeRequestError: LocalizedError, Equatable, Sendable {
    case notGitLab
    case notInstalled
    case notLoggedIn(host: String)
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .notGitLab: "The remote is not on GitLab"
        case .notInstalled: "glab is not installed. brew install glab"
        case .notLoggedIn(let host): "glab is not logged in to \(host)"
        case .command(let message): message
        }
    }
}
