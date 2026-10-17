import Foundation

package enum MergeRequestStateFilter: String, CaseIterable, Hashable, Sendable {
    case opened
    case merged
    case closed
    case all
}
