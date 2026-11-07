import Foundation

package enum ISOTimestamp {

    package static func text(_ date: Date) -> String {
        formatter.string(from: date)
    }

    package static func fileName(_ date: Date) -> String {
        fileFormatter.string(from: date)
    }

    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let fileFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        return formatter
    }()
}
