import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct FFmpegArgumentsTests {
    private let info = VideoFileInfo(duration: 5, width: 3456, height: 2234, frameRate: 60, codec: "h264", hasAudio: true, size: 2_000_000)

    @Test func balancedQualityScalesCapsTheFrameRateAndKeepsTheSound() {
        let arguments = FFmpegArguments.compress("/a/clip.mov", to: "/a/.clip compressed-AB12.mp4", info: info, settings: .standard)

        #expect(arguments == [
            "-hide_banner", "-nostdin", "-y", "-loglevel", "error", "-progress", "pipe:1", "-stats_period", "1", "-i", "/a/clip.mov",
            "-map", "0:v:0", "-map", "0:a:0?",
            "-c:v", "libx264", "-preset", "medium", "-crf", "24", "-pix_fmt", "yuv420p",
            "-fpsmax", "30", "-vf", "scale=1920:1240",
            "-c:a", "aac", "-b:a", "128k",
            "-movflags", "+faststart", "-f", "mp4", "/a/.clip compressed-AB12.mp4",
        ])
    }

    @Test func withoutSoundTheAudioIsDropped() {
        let arguments = FFmpegArguments.compress("/a/clip.mov", to: "/a/out.mp4", info: info, settings: VideoCompressionSettings(quality: .small, keepsAudio: false))

        #expect(arguments.contains("-an"))
        #expect(arguments.contains("0:a:0?") == false)
        #expect(arguments.contains("-c:a") == false)
        #expect(arguments.contains("scale=1280:826"))
    }

    @Test func eachQualityHasItsOwnRateFactor() {
        #expect(VideoQuality.allCases.map(FFmpegArguments.crf) == [20, 24, 28])
        #expect(VideoQuality.allCases.map(FFmpegArguments.audioBitrate) == ["160k", "128k", "96k"])
    }

    @Test func theEncoderListIsReadByName() {
        #expect(FFmpegArguments.hasEncoder("libx264", in: FFmpegFixture.encoders))
        #expect(FFmpegArguments.hasEncoder("libx264", in: FFmpegFixture.encodersWithoutX264) == false)
    }

    @Test func theProbeAsksForJSON() {
        #expect(FFmpegArguments.info("/a/clip.mov") == ["-v", "error", "-print_format", "json", "-show_format", "-show_streams", "/a/clip.mov"])
    }
}
