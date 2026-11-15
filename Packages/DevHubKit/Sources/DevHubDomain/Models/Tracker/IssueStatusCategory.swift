import Foundation

package enum IssueStatusCategory: String, CaseIterable, Codable, Hashable, Sendable {
    case toDo
    case inProgress
    case done
    case unknown
}
