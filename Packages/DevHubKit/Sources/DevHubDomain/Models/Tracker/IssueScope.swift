import Foundation

package enum IssueScope: String, CaseIterable, Codable, Hashable, Sendable {
    case mine
    case starred
    case recent
    case sprint
    case reported
    case watching
    case project
}
