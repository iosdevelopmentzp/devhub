import Foundation

package enum WorkTime {

    package static func text(seconds: Int) -> String {
        let total = max(seconds, 0)
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        switch (hours, minutes) {
        case (0, 0): return "0m"
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(minutes)m"
        }
    }
}
