import Foundation

package enum SimulatorStatusError: LocalizedError, Hashable, Sendable {
    case notFound(String)
    case timedOut
    case exited(Int32, lastLine: String?)

    package var errorDescription: String? {
        switch self {
        case let .notFound(script): "Status script not found: \(script)"
        case .timedOut: "status timed out"
        case let .exited(code, lastLine): lastLine ?? "Status script exited with code \(code)"
        }
    }
}
