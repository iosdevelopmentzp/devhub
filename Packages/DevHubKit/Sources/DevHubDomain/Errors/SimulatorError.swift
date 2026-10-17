import Foundation

package enum SimulatorError: LocalizedError, Sendable {
    case command(String)
    case malformedList

    package var errorDescription: String? {
        switch self {
        case .command(let message):
            message
        case .malformedList:
            "simctl returned an unexpected device list."
        }
    }
}
