import Foundation

package enum Countdown {

    package static func text(_ interval: TimeInterval) -> String? {
        formatter.string(from: max(interval, 0))
    }

    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}
