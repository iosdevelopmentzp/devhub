import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct VideoJobRowMapperTests {
    private let info = VideoFileInfo(duration: 40, width: 3456, height: 2234, frameRate: 60, codec: "h264", hasAudio: true, size: 80_000_000)

    private func job(_ state: VideoJob.State, info: VideoFileInfo? = nil) -> VideoJob {
        VideoJob(id: UUID(), source: "/Users/alex/Desktop/Screen Recording.mov", settings: .standard, info: info, state: state)
    }

    @Test func aWaitingVideoShowsItsFolderAndCanStop() {
        let model = VideoJobRowMapper.model(for: job(.waiting), isEngineReady: true)

        #expect(model.title == "Screen Recording.mov")
        #expect(model.facts == "/Users/alex/Desktop")
        #expect(model.status == "Waiting in the queue")
        #expect(model.qualityTag.text == "Balanced")
        #expect(model.canStop)
        #expect(model.canRemove)
    }

    @Test func aVideoWaitingForTheEngineSaysSo() {
        let model = VideoJobRowMapper.model(for: job(.waiting), isEngineReady: false)

        #expect(model.status == "Waiting for ffmpeg. Install it above.")
        #expect(model.statusTint == .orange)
    }

    @Test func aRunningVideoShowsTheProgressTheTimeLeftAndTheSpeed() {
        let model = VideoJobRowMapper.model(for: job(.compressing(VideoCompressionProgress(seconds: 10, speed: 3)), info: info), isEngineReady: true)

        #expect(model.progress == 0.25)
        #expect(model.status.hasPrefix("Compressing 25 % · "))
        #expect(model.status.hasSuffix(" left · 3.0× speed"))
        #expect(model.facts.hasPrefix("3456 × 2234 · 60 fps · "))
        #expect(model.canStop)
        #expect(model.canRemove == false)
    }

    @Test func aDoneVideoShowsTheSavingAndTheResult() {
        let result = VideoCompressionResult(path: "/Users/alex/Desktop/Screen Recording compressed.mp4", size: 8_000_000)

        let model = VideoJobRowMapper.model(for: job(.done(result, seconds: 12), info: info), isEngineReady: true)

        #expect(model.status.contains("90 % smaller"))
        #expect(model.statusTint == .green)
        #expect(model.resultName == "Screen Recording compressed.mp4")
        #expect(model.resultPath == result.path)
        #expect(model.canStop == false)
        #expect(model.canCompressAgain)
    }

    @Test func aResultLargerThanTheOriginalIsMarked() {
        let result = VideoCompressionResult(path: "/Users/alex/Desktop/Screen Recording compressed.mp4", size: 100_000_000)

        let model = VideoJobRowMapper.model(for: job(.done(result, seconds: 12), info: info), isEngineReady: true)

        #expect(model.status.contains("25 % larger"))
        #expect(model.statusTint == .orange)
    }

    @Test func aFailedVideoShowsTheReason() {
        let model = VideoJobRowMapper.model(for: job(.failed("Cannot read Screen Recording.mov: Invalid data")), isEngineReady: true)

        #expect(model.status == "Cannot read Screen Recording.mov: Invalid data")
        #expect(model.statusTint == .red)
        #expect(model.canCompressAgain)
        #expect(model.resultPath == nil)
    }

    @Test func aStoppedVideoSaysNoFileWasWritten() {
        let model = VideoJobRowMapper.model(for: job(.stopped), isEngineReady: true)

        #expect(model.status == "Stopped. No file was written.")
        #expect(model.canStop == false)
    }
}
