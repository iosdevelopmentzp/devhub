import Foundation

package enum MediaError: LocalizedError, Sendable {
    case noVideo(String)
    case cannotWrite(String)
    case exportFailed(String)
    case cannotRead(String)
    case noFrame(String)

    package var errorDescription: String? {
        switch self {
        case .noVideo(let path):
            "\((path as NSString).lastPathComponent) has no video track."
        case .cannotWrite(let path):
            "Cannot write \((path as NSString).lastPathComponent). Check that the folder exists and is writable."
        case .exportFailed(let message):
            "The video export failed: \(message)"
        case .cannotRead(let path):
            "Cannot read \((path as NSString).lastPathComponent)."
        case .noFrame(let reason):
            "No device frame: \(reason)"
        }
    }
}
