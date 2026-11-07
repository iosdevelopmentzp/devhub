import Foundation

package enum TrackerKind: String, Codable, Hashable, Sendable {
    case jira
    case disabled = "none"
}
