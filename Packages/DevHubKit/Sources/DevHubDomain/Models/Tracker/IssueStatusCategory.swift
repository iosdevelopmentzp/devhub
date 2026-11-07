import Foundation

package enum IssueStatusCategory: String, CaseIterable, Hashable, Sendable {
    case toDo
    case inProgress
    case done
    case unknown
}
