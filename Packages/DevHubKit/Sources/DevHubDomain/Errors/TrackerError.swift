import Foundation

package enum TrackerError: LocalizedError, Hashable, Sendable {
    case notInstalled
    case notConfigured
    case notLoggedIn
    case unreadable(String)
    case command(String)

    package var errorDescription: String? {
        switch self {
        case .notInstalled:
            "jira is not installed. brew install jira-cli"
        case .notConfigured:
            "jira is not set up. Run jira init in a terminal."
        case .notLoggedIn:
            "jira cannot log in: it found no token, or the server did not accept it. Put the token in the keychain (item jira-cli, account = the login of the jira config), in ~/.netrc, or export JIRA_API_TOKEN in ~/.zshrc, then check again."
        case .unreadable(let message):
            "Cannot read the answer of jira: \(message)"
        case .command(let message):
            message
        }
    }
}
