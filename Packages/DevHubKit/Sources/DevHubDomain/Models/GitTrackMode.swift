import Foundation

package enum GitTrackMode: Hashable, Sendable {
    case keepChanges
    case stashChanges
    case discardChanges
}
