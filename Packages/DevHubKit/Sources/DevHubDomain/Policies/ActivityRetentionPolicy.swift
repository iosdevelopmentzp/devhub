import Foundation

package enum ActivityRetentionPolicy {
    package static let days = 30
    package static let limit = 500

    package static func retained(_ events: [ActivityEvent], now: Date) -> [ActivityEvent] {
        let oldest = now.addingTimeInterval(-Double(days) * 86_400)
        return Array(events.filter { $0.date >= oldest }.prefix(limit))
    }
}
