import Foundation

nonisolated struct LogLineParser: Sendable {
    private let formatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        self.formatter = formatter
    }

    func parse(_ line: String) -> LogLine? {
        guard line.hasPrefix("{"), let data = line.data(using: .utf8) else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        guard let message = object["eventMessage"] as? String else { return nil }
        let date = (object["timestamp"] as? String).flatMap { formatter.date(from: $0) } ?? Date()
        return LogLine(
            id: UUID(),
            date: date,
            level: Self.level(object["messageType"] as? String),
            subsystem: object["subsystem"] as? String ?? "",
            category: object["category"] as? String ?? "",
            message: LogRedactor.redact(message)
        )
    }

    private static func level(_ name: String?) -> LogLine.Level {
        switch name?.lowercased() {
        case "debug": .debug
        case "info": .info
        case "error": .error
        case "fault": .fault
        default: .notice
        }
    }
}
