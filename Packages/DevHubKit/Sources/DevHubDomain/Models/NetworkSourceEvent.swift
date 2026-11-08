import Foundation

package enum NetworkSourceEvent: Hashable, Sendable {
    case request(NetworkRequest)
    case error(String)
    case output(String)
    case exited(Int32)
}
