import Foundation

package enum WorktreeLocation: Hashable, Sendable {
    case configured(folder: String)
    case insideProject
    case nextToProject
}
