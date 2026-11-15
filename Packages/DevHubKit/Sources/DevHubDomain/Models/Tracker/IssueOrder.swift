import Foundation

package enum IssueOrder: String, CaseIterable, Codable, Hashable, Sendable {
    case updated
    case created
    case priority
}
