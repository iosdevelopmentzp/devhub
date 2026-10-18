import Foundation
import DevHubDomain

struct GitHubCopilotUsageRepository: CopilotUsageRepository {
    private static let endpoint = URL(string: "https://api.github.com/copilot_internal/user")

    let tokenReader: CopilotTokenReader

    func fetch() async throws -> CopilotUsage? {
        guard let endpoint = Self.endpoint else { throw CopilotUsageError.malformedResponse }
        guard let token = try await tokenReader.read() else { return nil }

        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("token \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CopilotUsageError.malformedResponse }
        switch http.statusCode {
        case 200..<300: return try CopilotUsageParser.parse(data, now: .now)
        case 401, 403: throw CopilotUsageError.rejected
        default: throw CopilotUsageError.http(http.statusCode)
        }
    }
}
