import Foundation

package enum TicketPrefix {
    package static func prefix(forBranch branch: String, ticket: TicketSettings) -> String? {
        guard let regex = try? NSRegularExpression(pattern: ticket.pattern) else { return nil }
        guard let match = regex.firstMatch(in: branch, range: NSRange(branch.startIndex..., in: branch)) else { return nil }
        return regex.replacementString(for: match, in: branch, offset: 0, template: ticket.format)
    }

    package static func key(in text: String, ticket: TicketSettings) -> String? {
        let search = ticket.pattern.hasPrefix("^") ? String(ticket.pattern.dropFirst()) : ticket.pattern
        guard let regex = try? NSRegularExpression(pattern: search) else { return nil }
        guard let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        let range = match.numberOfRanges > 1 && match.range(at: 1).location != NSNotFound ? match.range(at: 1) : match.range
        return Range(range, in: text).map { String(text[$0]) }
    }

    package static func url(forKey key: String, template: String) -> URL? {
        let trimmed = template.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("{key}") else { return nil }
        return URL(string: trimmed.replacingOccurrences(of: "{key}", with: key))
    }
}
