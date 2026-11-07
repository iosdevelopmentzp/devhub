import Foundation

package enum AttachDestination: Hashable, Sendable {
    case simulator(String)
    case device(String)

    package var udid: String {
        switch self {
        case .simulator(let udid), .device(let udid): udid
        }
    }
}
