import Foundation
import DevHubDomain

enum AppLogParser {
    private struct Event: Decodable {
        let timestamp: String?
        let messageType: String?
        let subsystem: String?
        let category: String?
        let eventMessage: String?
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
        return formatter
    }()

    static func parse(_ line: String, id: Int) -> AppLogLine? {
        guard line.hasPrefix("{"), let data = line.data(using: .utf8),
              let event = try? JSONDecoder().decode(Event.self, from: data),
              let message = event.eventMessage else { return nil }
        let category = [event.subsystem, event.category]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: " · ")
        return AppLogLine(
            id: id,
            date: event.timestamp.flatMap { formatter.date(from: $0) },
            level: level(event.messageType),
            category: category,
            message: LogRedactor.redact(message)
        )
    }

    private static func level(_ type: String?) -> AppLogLine.Level {
        switch type {
        case "Debug": .debug
        case "Info": .info
        case "Error": .error
        case "Fault": .fault
        default: .notice
        }
    }
}
