import Foundation

nonisolated struct LogLine: Identifiable, Hashable, Sendable {
    enum Level: Int, Hashable, Sendable, Comparable {
        case debug
        case info
        case notice
        case error
        case fault

        static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    let id: UUID
    let date: Date
    var level: Level
    var subsystem: String
    var category: String
    var message: String

    var source: String {
        [subsystem, category].filter { $0.isEmpty == false }.joined(separator: " · ")
    }
}

nonisolated extension LogLine {
    var plainText: String {
        let time = date.formatted(Date.FormatStyle().hour(.twoDigits(amPM: .omitted)).minute().second())
        let parts = [time, source, message].filter { $0.isEmpty == false }
        return parts.joined(separator: " ")
    }
}
