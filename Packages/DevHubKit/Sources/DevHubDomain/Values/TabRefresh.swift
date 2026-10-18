import Foundation

package enum TabRefresh: Hashable, Sendable {
    case onOpen
    case manual
    case every(seconds: Int)
}
