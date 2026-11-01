import Foundation

package enum MediaError: LocalizedError, Sendable {
    case noVideo(String)
    case cannotWrite(String)
    case exportFailed(String)

    package var errorDescription: String? {
        switch self {
        case .noVideo(let path):
            "\((path as NSString).lastPathComponent) has no video track."
        case .cannotWrite(let path):
            "Cannot write \((path as NSString).lastPathComponent). Check that the folder exists and is writable."
        case .exportFailed(let message):
            "The video export failed: \(message)"
        }
    }
}
