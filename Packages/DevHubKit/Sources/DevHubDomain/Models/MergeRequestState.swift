import Foundation

package enum MergeRequestState: Hashable, Sendable {
    case opened
    case merged
    case closed
    case locked
    case other(String)

    package var name: String {
        switch self {
        case .opened: "opened"
        case .merged: "merged"
        case .closed: "closed"
        case .locked: "locked"
        case .other(let name): name
        }
    }
}
