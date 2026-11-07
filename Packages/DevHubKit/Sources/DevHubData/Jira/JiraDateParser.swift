import Foundation
import DevHubDomain

enum JiraDateParser {
    static func date(from text: String) -> Date? {
        let trimmed = text.trimmed
        let pattern = "([+-])(\\d{2})(\\d{2})$"
        let normalized = trimmed.replacingOccurrences(of: pattern, with: "$1$2:$3", options: .regularExpression)
        return ISO8601.date(from: normalized)
    }
}
