import Foundation
import DevHubDomain

struct ClaudeCredentials {
    let accessToken: String
    let expiresAt: Date?
    let subscriptionType: String?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= .now
    }
}
