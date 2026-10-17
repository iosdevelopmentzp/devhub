import Foundation

package struct AppLogLine: Identifiable, Hashable, Sendable {
    package enum Level: Int, Comparable, CaseIterable, Sendable {
        case debug
        case info
        case notice
        case error
        case fault

        package static func < (lhs: Level, rhs: Level) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    package let id: Int
    package let date: Date?
    package let level: Level
    package let category: String
    package let message: String

    package init(id: Int, date: Date?, level: Level, category: String, message: String) {
        self.id = id
        self.date = date
        self.level = level
        self.category = category
        self.message = message
    }
}
