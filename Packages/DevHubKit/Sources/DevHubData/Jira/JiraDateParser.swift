import Foundation
import DevHubDomain

enum JiraDateParser {
    static func date(from text: String) -> Date? {
        let trimmed = text.trimmed
        let pattern = "([+-])(\\d{2})(\\d{2})$"
        let normalized = trimmed.replacingOccurrences(of: pattern, with: "$1$2:$3", options: .regularExpression)
        return ISO8601.date(from: normalized)
    }

    static func day(from text: String, calendar: Calendar) -> Date? {
        guard let match = text.wholeMatch(of: /([0-9]{4})-([0-9]{2})-([0-9]{2})/) else { return nil }
        let components = DateComponents(year: Int(match.1), month: Int(match.2), day: Int(match.3))
        guard components.isValidDate(in: calendar) else { return nil }
        return calendar.date(from: components)
    }
}
