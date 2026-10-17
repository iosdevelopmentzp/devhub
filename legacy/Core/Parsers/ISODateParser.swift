import Foundation

nonisolated enum ISODateParser {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value) {
            return date
        }
        if let date = try? Date.ISO8601FormatStyle().parse(value) {
            return date
        }
        return try? Date.ISO8601FormatStyle().year().month().day().parse(value)
    }
}
