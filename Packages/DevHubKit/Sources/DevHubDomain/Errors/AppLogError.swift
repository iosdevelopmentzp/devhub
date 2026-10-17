import Foundation

package enum AppLogError: LocalizedError, Sendable {
    case streamStopped(Int32)

    package var errorDescription: String? {
        switch self {
        case .streamStopped(let status): "log stream stopped with exit code \(status). Is the simulator still booted?"
        }
    }
}
