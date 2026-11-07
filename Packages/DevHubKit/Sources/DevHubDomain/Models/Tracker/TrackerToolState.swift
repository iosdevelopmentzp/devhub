import Foundation

package enum TrackerToolState: Hashable, Sendable {
    case missing
    case notConfigured
    case notLoggedIn
    case failed(String)
    case ready(version: String?, user: String?)

    package var isReady: Bool {
        guard case .ready = self else { return false }
        return true
    }
}
