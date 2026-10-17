import Foundation

package enum TicketPrefix {

    package static func prefix(forBranch branch: String) -> String? {
        guard let match = branch.firstMatch(of: /^[A-Z][A-Z0-9]+-\d+/) else { return nil }
        return "\(match.output): "
    }

    package static func key(in text: String) -> String? {
        text.firstMatch(of: /[A-Z][A-Z0-9]+-\d+/).map { String($0.output) }
    }

    package static func url(forKey key: String, template: String) -> URL? {
        let trimmed = template.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("{key}") else { return nil }
        return URL(string: trimmed.replacingOccurrences(of: "{key}", with: key))
    }
}
