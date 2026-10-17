import Foundation

package enum MockSetError: LocalizedError, Equatable {
    case unreadable(file: String, reason: String)
    case writeFailed(String)

    package var errorDescription: String? {
        switch self {
        case .unreadable(let file, let reason):
            "The mock set file \(file) cannot be read: \(reason) Fix or delete the file."
        case .writeFailed(let message):
            "The mock set was not saved: \(message)"
        }
    }
}
