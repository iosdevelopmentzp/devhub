import Foundation

nonisolated enum SessionText {
    static let limit = 300

    static func oneLine(_ value: String, limit: Int = SessionText.limit) -> String {
        let head = String(value.prefix(limit * 4))
        let collapsed = head
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit - 1)) + "…"
    }

    static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let line = oneLine(value)
        return line.isEmpty ? nil : line
    }
}
