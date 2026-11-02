import Foundation
import DevHubDomain

extension MockData {
    package static let screenRecording = VideoFileInfo(duration: 42.5, width: 3456, height: 2234, frameRate: 60, codec: "h264", hasAudio: false, size: 86_400_000)

    package static let homebrewSteps = [
        "Downloading Homebrew API data",
        "Fetching downloads for: ffmpeg",
        "Installing ffmpeg dependency: x264 (r3222)",
        "Pouring ffmpeg--9.0.2_1.arm64_tahoe.bottle.tar.gz",
    ]
}
