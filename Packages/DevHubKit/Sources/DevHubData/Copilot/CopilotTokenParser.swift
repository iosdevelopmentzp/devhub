import Foundation
import DevHubDomain

enum CopilotTokenParser {
    private static let tokenFields = ["oauth_token", "access_token", "token", "accessToken"]

    static func parse(_ text: String) -> String? {
        let trimmed = text.trimmed
        guard trimmed.isEmpty == false else { return nil }
        guard trimmed.hasPrefix("{") else { return trimmed }
        guard let object = (try? JSONSerialization.jsonObject(with: Data(trimmed.utf8))) as? [String: Any] else { return nil }
        return tokenFields.lazy.compactMap { object[$0] as? String }.first { $0.isEmpty == false }
    }
}
