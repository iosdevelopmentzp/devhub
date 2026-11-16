import Foundation

package enum PullRequestError: LocalizedError, Equatable, Sendable {
    case noCodeHost
    case notInstalled(tool: String)
    case notLoggedIn(tool: String, host: String)
    case missingScope(tool: String, host: String, scope: String)
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .noCodeHost: "The remote has no web address on GitHub or GitLab"
        case .notInstalled(let tool): "\(tool) is not installed. brew install \(tool)"
        case .notLoggedIn(let tool, let host): "\(tool) is not logged in to \(host). Run \(tool) auth login --hostname \(host)"
        case .missingScope(let tool, let host, let scope): "The \(tool) login has no \(scope) scope. Run \(tool) auth refresh --hostname \(host) --scopes \(scope)"
        case .command(let message): message
        }
    }
}
