import Foundation
import DevHubDomain

enum FFmpegVersionParser {
    static func version(from output: String) -> String? {
        guard let range = output.range(of: #"ffmpeg version \S+"#, options: .regularExpression) else { return nil }
        return String(output[range].dropFirst("ffmpeg version ".count))
    }
}
