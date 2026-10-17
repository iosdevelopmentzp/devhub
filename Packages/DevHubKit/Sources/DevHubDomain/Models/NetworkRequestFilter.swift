import Foundation

package enum NetworkRequestFilter: String, CaseIterable, Sendable {
    case all
    case failed
    case slow

    package static let slowThreshold: TimeInterval = 1

    package func matches(_ request: NetworkRequest) -> Bool {
        switch self {
        case .all: true
        case .failed: request.isFailure || (request.statusCode ?? 0) >= 400
        case .slow: (request.duration ?? 0) > Self.slowThreshold
        }
    }
}
