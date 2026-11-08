import Foundation

package enum NetworkSourceError: LocalizedError, Hashable, Sendable {
    case notFound(String)
    case exited(Int32, lastLine: String?)

    package var errorDescription: String? {
        switch self {
        case let .notFound(script): "Network source script not found: \(script)"
        case let .exited(code, lastLine): lastLine.map { "The network source script stopped: \($0)" } ?? "The network source script exited with code \(code)"
        }
    }
}
