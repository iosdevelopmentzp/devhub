import Foundation

nonisolated struct ClaudeCredentials: Sendable {
    let accessToken: String
    let expiresAt: Date?
    let plan: String?

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}

nonisolated enum ClaudeCredentialsParser {
    static func parse(_ text: String) -> ClaudeCredentials? {
        guard let data = text.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let oauth = root["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String,
              token.isEmpty == false
        else { return nil }
        let expiresMilliseconds = UsageNumber.double(oauth["expiresAt"])
        return ClaudeCredentials(
            accessToken: token,
            expiresAt: expiresMilliseconds.map { Date(timeIntervalSince1970: $0 / 1000) },
            plan: (oauth["subscriptionType"] as? String).flatMap { $0.isEmpty ? nil : $0.capitalized }
        )
    }
}
