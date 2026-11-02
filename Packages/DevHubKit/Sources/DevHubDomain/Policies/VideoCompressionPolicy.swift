import Foundation

package enum VideoCompressionPolicy {
    package static let videoExtensions: Set<String> = ["mov", "mp4", "m4v", "mkv", "webm", "avi"]
    package static let outputSuffix = " compressed"

    package static func isVideo(_ path: String) -> Bool {
        videoExtensions.contains((path as NSString).pathExtension.lowercased())
    }

    package static func outputPath(for source: String, exists: (String) -> Bool) -> String {
        MediaOutputPolicy.uniquePath(stem: (source as NSString).deletingPathExtension, suffix: outputSuffix, fileExtension: "mp4", exists: exists)
    }

    package static func partialPath(for output: String, token: String) -> String {
        let folder = (output as NSString).deletingLastPathComponent
        let name = ((output as NSString).lastPathComponent as NSString).deletingPathExtension
        return (folder as NSString).appendingPathComponent(".\(name)-\(token).mp4")
    }

    package static func outputSize(width: Int, height: Int, quality: VideoQuality) -> (width: Int, height: Int) {
        let longSide = max(width, height)
        let scale = quality.maximumLongSide.map { longSide > $0 ? Double($0) / Double(longSide) : 1 } ?? 1
        return (even(Double(width) * scale), even(Double(height) * scale))
    }

    package static func fraction(done: Double, duration: Double) -> Double {
        guard duration > 0 else { return 0 }
        return min(max(done / duration, 0), 1)
    }

    package static func remaining(done: Double, duration: Double, speed: Double?) -> Double? {
        guard let speed, speed > 0, duration > 0 else { return nil }
        return max(duration - done, 0) / speed
    }

    package static func saving(original: Int64, compressed: Int64) -> Double {
        guard original > 0 else { return 0 }
        return 1 - Double(compressed) / Double(original)
    }

    private static func even(_ value: Double) -> Int {
        max(Int(value.rounded(.down)) / 2 * 2, 2)
    }
}
