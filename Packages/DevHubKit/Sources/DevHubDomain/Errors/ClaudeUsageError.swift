import Foundation

package enum ClaudeUsageError: LocalizedError, Sendable {
    case notLoggedIn
    case tokenExpired
    case http(Int)
    case malformedResponse

    package var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            "Claude Code is not logged in. Run `claude` and sign in."
        case .tokenExpired:
            "Claude Code token expired. Run `claude` once to refresh it."
        case .http(let code):
            code == 401 ? "Token rejected (401). Run `claude` once to refresh it." : "Usage request failed (HTTP \(code))."
        case .malformedResponse:
            "Usage response had an unexpected format."
        }
    }
}
