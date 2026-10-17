import Foundation
import DevHubDomain

enum ISO8601 {
    private static let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let plain = Date.ISO8601FormatStyle()

    static func date(from string: String) -> Date? {
        (try? fractional.parse(string)) ?? (try? plain.parse(string))
    }
}
