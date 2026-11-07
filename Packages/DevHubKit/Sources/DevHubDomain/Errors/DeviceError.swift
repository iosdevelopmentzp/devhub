import Foundation

package enum DeviceError: LocalizedError, Sendable {
    case command(String)
    case malformedList

    package var errorDescription: String? {
        switch self {
        case .command(let message):
            message
        case .malformedList:
            "devicectl returned an unexpected device list."
        }
    }
}
