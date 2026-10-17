import Foundation

package enum PullRequestStateFilter: String, CaseIterable, Hashable, Sendable {
    case opened
    case merged
    case closed
    case all
}
