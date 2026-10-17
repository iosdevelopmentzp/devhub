import Foundation
import DevHubDomain

struct AnthropicUsageRepository: ClaudeUsageRepository {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")

    let credentialsReader: ClaudeCredentialsReader

    func fetch() async throws -> ClaudeUsage {
        guard let endpoint = Self.endpoint else { throw ClaudeUsageError.malformedResponse }
        let credentials = try await credentialsReader.read()
        guard credentials.isExpired == false else { throw ClaudeUsageError.tokenExpired }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClaudeUsageError.malformedResponse }
        guard (200..<300).contains(http.statusCode) else { throw ClaudeUsageError.http(http.statusCode) }
        return try ClaudeUsageParser.parse(data, plan: credentials.subscriptionType, now: .now)
    }
}
