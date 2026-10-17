import Foundation

package enum ConfigLayer: String, Hashable, Sendable {
    case user
    case project
    case global

    package var rank: Int {
        switch self {
        case .user: 0
        case .project: 1
        case .global: 2
        }
    }
}
