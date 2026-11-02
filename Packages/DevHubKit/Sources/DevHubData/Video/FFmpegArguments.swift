import Foundation
import DevHubDomain

enum FFmpegArguments {
    static let version = ["-hide_banner", "-version"]
    static let encoders = ["-hide_banner", "-encoders"]
    static let install = ["install", "ffmpeg"]
    static let installEnvironment = ["HOMEBREW_NO_ENV_HINTS": "1"]

    static func info(_ path: String) -> [String] {
        ["-v", "error", "-print_format", "json", "-show_format", "-show_streams", path]
    }

    static func compress(_ input: String, to output: String, info: VideoFileInfo, settings: VideoCompressionSettings) -> [String] {
        let quality = settings.quality
        let size = VideoCompressionPolicy.outputSize(width: info.width, height: info.height, quality: quality)
        let audio = settings.keepsAudio ? ["-c:a", "aac", "-b:a", audioBitrate(for: quality)] : ["-an"]
        return ["-hide_banner", "-nostdin", "-y", "-loglevel", "error", "-progress", "pipe:1", "-stats_period", "1", "-i", input]
            + ["-map", "0:v:0"] + (settings.keepsAudio ? ["-map", "0:a:0?"] : [])
            + ["-c:v", "libx264", "-preset", "medium", "-crf", String(crf(for: quality)), "-pix_fmt", "yuv420p"]
            + ["-fpsmax", String(quality.maximumFrameRate), "-vf", "scale=\(size.width):\(size.height)"]
            + audio
            + ["-movflags", "+faststart", "-f", "mp4", output]
    }

    static func crf(for quality: VideoQuality) -> Int {
        switch quality {
        case .high: 20
        case .balanced: 24
        case .small: 28
        }
    }

    static func audioBitrate(for quality: VideoQuality) -> String {
        switch quality {
        case .high: "160k"
        case .balanced: "128k"
        case .small: "96k"
        }
    }

    static func hasEncoder(_ name: String, in output: String) -> Bool {
        output.split(separator: "\n").contains { line in
            line.split(separator: " ").dropFirst().first == Substring(name)
        }
    }
}
