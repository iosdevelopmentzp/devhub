import Foundation
import DevHubDomain

enum ClaudeCredentialsParser {
    static func parse(_ data: Data) throws -> ClaudeCredentials {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let oauth = root["claudeAiOauth"] as? [String: Any],
            let accessToken = oauth["accessToken"] as? String,
            accessToken.isEmpty == false
        else {
            throw ClaudeUsageError.notLoggedIn
        }
        let expiresAt = (oauth["expiresAt"] as? Double).map { Date(timeIntervalSince1970: $0 / 1000) }
        return ClaudeCredentials(
            accessToken: accessToken,
            expiresAt: expiresAt,
            subscriptionType: oauth["subscriptionType"] as? String
        )
    }
}
