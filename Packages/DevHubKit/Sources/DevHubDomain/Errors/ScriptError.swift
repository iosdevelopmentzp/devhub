import Foundation

package enum ScriptError: LocalizedError, Hashable, Sendable {
    case timedOut(Duration)

    package var errorDescription: String? {
        switch self {
        case let .timedOut(duration): "The script did not finish within \(duration.components.seconds) s and was stopped."
        }
    }
}
