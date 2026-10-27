import Foundation

package enum SleepPreventionError: LocalizedError, Sendable {
    case assertionFailed(Int32)

    package var errorDescription: String? {
        switch self {
        case .assertionFailed(let code): "macOS refused the power assertion (code \(code))"
        }
    }
}
