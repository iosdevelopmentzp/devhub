import Foundation

package enum MockAction: Hashable, Sendable {
    case respond(MockResponse)
    case patch(MockPatch)

    package var delay: TimeInterval {
        switch self {
        case .respond(let response): response.delay
        case .patch(let patch): patch.delay
        }
    }
}
