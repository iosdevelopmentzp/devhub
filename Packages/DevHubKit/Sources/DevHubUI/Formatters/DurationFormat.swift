import Foundation

package enum DurationFormat {

    package static func text(_ seconds: TimeInterval) -> String {
        if seconds < 1 { return "\(Int(seconds * 1000)) ms" }
        if seconds < 60 { return String(format: "%.1f s", seconds) }
        return "\(Int(seconds) / 60) m \(Int(seconds) % 60) s"
    }
}
