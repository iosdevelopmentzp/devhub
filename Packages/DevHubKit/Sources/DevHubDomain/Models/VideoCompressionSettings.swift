import Foundation

package struct VideoCompressionSettings: Hashable, Codable, Sendable {
    package static let standard = VideoCompressionSettings(quality: .balanced, keepsAudio: true)

    package var quality: VideoQuality
    package var keepsAudio: Bool

    package init(quality: VideoQuality, keepsAudio: Bool) {
        self.quality = quality
        self.keepsAudio = keepsAudio
    }
}
