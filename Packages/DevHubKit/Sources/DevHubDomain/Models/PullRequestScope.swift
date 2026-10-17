import Foundation

package enum PullRequestScope: String, CaseIterable, Hashable, Sendable {
    case mine
    case reviewing
    case assigned
    case all
}
