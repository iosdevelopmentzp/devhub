import Foundation

package struct VideoFileInfo: Hashable, Sendable {
    package var duration: Double
    package var width: Int
    package var height: Int
    package var frameRate: Double?
    package var codec: String
    package var hasAudio: Bool
    package var size: Int64

    package init(duration: Double, width: Int, height: Int, frameRate: Double?, codec: String, hasAudio: Bool, size: Int64) {
        self.duration = duration
        self.width = width
        self.height = height
        self.frameRate = frameRate
        self.codec = codec
        self.hasAudio = hasAudio
        self.size = size
    }
}
