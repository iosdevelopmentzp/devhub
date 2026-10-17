import Foundation

package enum LogTimestamp {

    package static func text(_ date: Date?) -> String {
        date.map { formatter.string(from: $0) } ?? ""
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}
