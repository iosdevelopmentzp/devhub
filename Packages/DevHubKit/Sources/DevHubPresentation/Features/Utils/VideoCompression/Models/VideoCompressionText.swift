import Foundation
import DevHubDomain
import DevHubUI

enum VideoCompressionText {
    static let homebrewPage = URL(string: "https://github.com/Homebrew/brew/releases/latest")
    static let installCommand = "brew install ffmpeg"
    static let reinstallCommand = "brew reinstall ffmpeg"

    static func title(for quality: VideoQuality) -> String {
        switch quality {
        case .high: "High"
        case .balanced: "Balanced"
        case .small: "Small"
        }
    }

    static func description(for quality: VideoQuality) -> String {
        switch quality {
        case .high: "The same size and up to 60 fps. The best detail; the file stays larger."
        case .balanced: "Up to 1920 px and 30 fps. Sharp text and a much smaller file. Good for most recordings."
        case .small: "Up to 1280 px and 30 fps. The smallest file for a chat; small text can blur."
        }
    }

    static func facts(of info: VideoFileInfo) -> String {
        var parts = ["\(info.width) × \(info.height)"]
        if let rate = info.frameRate {
            parts.append("\(Int(rate.rounded())) fps")
        }
        parts.append(DurationFormat.text(info.duration))
        parts.append(ByteFormat.text(info.size))
        if info.hasAudio == false {
            parts.append("no sound")
        }
        return parts.joined(separator: " · ")
    }

    static func change(original: Int64, compressed: Int64) -> String {
        let saving = VideoCompressionPolicy.saving(original: original, compressed: compressed)
        let percent = Int((abs(saving) * 100).rounded())
        let sizes = "\(ByteFormat.text(original)) → \(ByteFormat.text(compressed))"
        return saving >= 0 ? "\(sizes), \(percent) % smaller" : "\(sizes), \(percent) % larger"
    }
}
