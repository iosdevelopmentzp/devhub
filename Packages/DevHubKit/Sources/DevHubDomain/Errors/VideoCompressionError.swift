import Foundation

package enum VideoCompressionError: LocalizedError, Hashable, Sendable {
    case engineMissing
    case homebrewMissing
    case notAVideo(String)
    case unreadable(String, reason: String)
    case command(String)
    case installFailed(String)

    package var errorDescription: String? {
        switch self {
        case .engineMissing:
            "ffmpeg is not installed. Install it in Utils, or run: brew install ffmpeg"
        case .homebrewMissing:
            "Homebrew is not installed. Install Homebrew first, then ffmpeg."
        case .notAVideo(let name):
            "\(name) is not a video. Use a .mov, .mp4, .m4v, .mkv, .webm or .avi file."
        case .unreadable(let name, let reason):
            "Cannot read \(name): \(reason)"
        case .command(let message):
            message
        case .installFailed(let message):
            "brew install ffmpeg failed: \(message)"
        }
    }
}
