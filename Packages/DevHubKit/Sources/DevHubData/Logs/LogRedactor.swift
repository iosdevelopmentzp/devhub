import Foundation
import DevHubDomain

enum LogRedactor {
    private struct Rule {
        let regex: NSRegularExpression
        let template: String
    }

    private static let mask = "•••"

    private static let rules: [Rule] = [
        (#"(?i)(bearer\s+)[A-Za-z0-9\-._~+/]+=*"#, "$1\(mask)"),
        (#"eyJ[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+\.[A-Za-z0-9_\-]+"#, mask),
        (#"(?i)("?(?:authorization|x-auth-token|access_?token|refresh_?token|id_?token|token|password|secret|api_?key)"?\s*[:=]\s*"?)[^"\s,;}&]+"#, "$1\(mask)"),
    ].compactMap { pattern, template in
        (try? NSRegularExpression(pattern: pattern)).map { Rule(regex: $0, template: template) }
    }

    static func redact(_ text: String) -> String {
        rules.reduce(text) { result, rule in
            rule.regex.stringByReplacingMatches(in: result, range: NSRange(result.startIndex..., in: result), withTemplate: rule.template)
        }
    }
}
