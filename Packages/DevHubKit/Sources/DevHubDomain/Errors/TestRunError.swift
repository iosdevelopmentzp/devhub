import Foundation

package enum TestRunError: LocalizedError, Sendable {
    case failed(String)

    package var errorDescription: String? {
        switch self {
        case .failed(let message):
            message
        }
    }
}
