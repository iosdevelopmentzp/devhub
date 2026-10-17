import Foundation

nonisolated enum LogRedactor {
    static let mask = "***"

    private static let keys = ["authorization", "x-auth-token", "access_token", "refresh_token", "id_token", "token", "password", "secret", "api_key"]

    private static let rules: [(NSRegularExpression, String)] = {
        let keyPattern = keys.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        let sources: [(String, String)] = [
            ("\\beyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]*", mask),
            ("(?i)\\bBearer\\s+[A-Za-z0-9._~+/=-]+", "Bearer " + mask),
            ("(?i)([\"']?\\b(?:\(keyPattern))\\b[\"']?\\s*[:=]\\s*)(?:\"[^\"]*\"|'[^']*'|(?:Bearer\\s+)?[^\\s,;&}\\]\"']+)", "$1" + mask)
        ]
        return sources.compactMap { source, template in
            (try? NSRegularExpression(pattern: source)).map { ($0, template) }
        }
    }()

    static func redact(_ text: String) -> String {
        var result = text
        for (expression, template) in rules {
            let range = NSRange(result.startIndex..., in: result)
            result = expression.stringByReplacingMatches(in: result, range: range, withTemplate: template)
        }
        return result
    }
}
