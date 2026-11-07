import Foundation

package enum DeviceError: LocalizedError, Sendable {
    case command(String)
    case malformedList
    case attachNotAvailable

    package var errorDescription: String? {
        switch self {
        case .command(let message):
            message
        case .malformedList:
            "devicectl returned an unexpected device list."
        case .attachNotAvailable:
            "Run & Attach is not available on a physical device yet. Use Build & Run, then attach Xcode by hand."
        }
    }
}
