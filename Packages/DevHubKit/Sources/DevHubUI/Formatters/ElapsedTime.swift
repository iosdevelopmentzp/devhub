import Foundation

package enum ElapsedTime {

    package static func text(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds))
        let hours = total / 3600
        let minutes = total % 3600 / 60
        let rest = total % 60
        guard hours > 0 else { return String(format: "%d:%02d", minutes, rest) }
        return String(format: "%d:%02d:%02d", hours, minutes, rest)
    }
}
