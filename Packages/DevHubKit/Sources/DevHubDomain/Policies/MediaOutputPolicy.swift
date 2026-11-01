import Foundation

package enum MediaOutputPolicy {
    package static let maximumFrames = 600
    package static let videoExtensions: Set<String> = ["mov", "mp4", "m4v"]

    package static func gifPlan(duration: Double, naturalWidth: Double, naturalHeight: Double, options: GIFOptions) -> GIFPlan {
        let framesPerSecond = max(options.framesPerSecond, 1)
        let wanted = max(Int((max(duration, 0) * Double(framesPerSecond)).rounded(.down)), 1)
        let count = min(wanted, maximumFrames)
        let step = wanted > maximumFrames ? duration / Double(maximumFrames) : 1 / Double(framesPerSecond)
        let width = naturalWidth > 0 ? min(options.width, Int(naturalWidth)) : options.width
        let height = naturalWidth > 0 ? Int((Double(width) * naturalHeight / naturalWidth).rounded()) : width
        return GIFPlan(times: (0..<count).map { Double($0) * step }, delay: step, width: width, height: height)
    }

    package static func gifPath(for source: String, exists: (String) -> Bool) -> String {
        uniquePath(stem: stem(of: source), suffix: "", fileExtension: "gif", exists: exists)
    }

    package static func compressedPath(for source: String, compression: VideoCompression, exists: (String) -> Bool) -> String {
        let suffix = switch compression {
        case .h264At720p: " 720p"
        case .hevcAt1080p: " HEVC 1080p"
        }
        return uniquePath(stem: stem(of: source), suffix: suffix, fileExtension: "mp4", exists: exists)
    }

    package static func isVideo(_ path: String) -> Bool {
        videoExtensions.contains((path as NSString).pathExtension.lowercased())
    }

    private static func stem(of source: String) -> String {
        (source as NSString).deletingPathExtension
    }

    private static func uniquePath(stem: String, suffix: String, fileExtension: String, exists: (String) -> Bool) -> String {
        let first = "\(stem)\(suffix).\(fileExtension)"
        guard exists(first) else { return first }
        var index = 2
        while exists("\(stem)\(suffix) \(index).\(fileExtension)") {
            index += 1
        }
        return "\(stem)\(suffix) \(index).\(fileExtension)"
    }
}
