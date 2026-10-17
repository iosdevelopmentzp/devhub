import Foundation

package enum MockMode: String, CaseIterable, Codable, Sendable {
    case off
    case passthrough
    case mock
}
