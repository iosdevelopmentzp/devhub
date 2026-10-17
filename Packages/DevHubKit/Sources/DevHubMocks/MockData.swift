import Foundation
import DevHubDomain

package enum MockData {
    package static let now = Date()

    package static func ago(minutes: Double = 0, hours: Double = 0, days: Double = 0) -> Date {
        now.addingTimeInterval(-(minutes * 60 + hours * 3600 + days * 86400))
    }
}
