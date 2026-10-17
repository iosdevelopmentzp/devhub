import Foundation

package enum MergeRequestScope: String, CaseIterable, Hashable, Sendable {
    case mine
    case reviewing
    case assigned
    case all
}
