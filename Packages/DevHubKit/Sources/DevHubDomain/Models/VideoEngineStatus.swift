import Foundation

package enum VideoEngineStatus: Hashable, Sendable {
    case ready(version: String, path: String)
    case incomplete(version: String, path: String, missing: String)
    case missing(homebrewPath: String?)

    package var isReady: Bool {
        guard case .ready = self else { return false }
        return true
    }
}
