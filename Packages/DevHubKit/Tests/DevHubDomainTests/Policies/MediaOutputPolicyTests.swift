import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MediaOutputPolicyTests {
    @Test func aShortVideoGetsOneFramePerStep() {
        let plan = MediaOutputPolicy.gifPlan(duration: 2, naturalWidth: 1206, naturalHeight: 2622, options: GIFOptions(width: 480, framesPerSecond: 10))

        #expect(plan.times.count == 20)
        #expect(plan.times.prefix(3) == [0, 0.1, 0.2])
        #expect(plan.delay == 0.1)
        #expect(plan.width == 480)
        #expect(plan.height == 1044)
    }

    @Test func aLongVideoKeepsTheFrameLimitAndSlowsTheSteps() {
        let plan = MediaOutputPolicy.gifPlan(duration: 100, naturalWidth: 1206, naturalHeight: 2622, options: GIFOptions(width: 480, framesPerSecond: 15))

        #expect(plan.times.count == MediaOutputPolicy.maximumFrames)
        #expect(abs(plan.delay - 100.0 / 600.0) < 0.0001)
    }

    @Test func aVideoShorterThanOneFrameStillGetsOneFrame() {
        let plan = MediaOutputPolicy.gifPlan(duration: 0.05, naturalWidth: 100, naturalHeight: 200, options: GIFOptions(width: 480, framesPerSecond: 10))

        #expect(plan.times == [0])
    }

    @Test func aSmallVideoIsNotScaledUp() {
        let plan = MediaOutputPolicy.gifPlan(duration: 1, naturalWidth: 300, naturalHeight: 600, options: GIFOptions(width: 640, framesPerSecond: 10))

        #expect(plan.width == 300)
        #expect(plan.height == 600)
    }

    @Test func aStillScreenBecomesOneLongFrame() {
        let plan = GIFPlan(times: [0, 0.1, 0.2, 0.3, 0.4, 0.5], delay: 0.1, width: 480, height: 1044)

        let frames = MediaOutputPolicy.gifFrames(plan: plan, sampleTimes: [0, 0.095, 3.4])

        #expect(frames.map(\.sample) == [0, 1])
        #expect(abs(frames[0].delay - 0.1) < 0.0001)
        #expect(abs(frames[1].delay - 0.5) < 0.0001)
    }

    @Test func eachStepTakesTheLastSampleShownAtThatTime() {
        let plan = GIFPlan(times: [0, 0.2, 0.4], delay: 0.2, width: 80, height: 160)

        let frames = MediaOutputPolicy.gifFrames(plan: plan, sampleTimes: [0, 0.1, 0.2, 0.3, 0.4, 0.5])

        #expect(frames == [GIFFrame(sample: 0, delay: 0.2), GIFFrame(sample: 2, delay: 0.2), GIFFrame(sample: 4, delay: 0.2)])
    }

    @Test func aStepBeforeTheFirstSampleShowsTheFirstSample() {
        let plan = GIFPlan(times: [0, 0.1], delay: 0.1, width: 80, height: 160)

        let frames = MediaOutputPolicy.gifFrames(plan: plan, sampleTimes: [0.05, 0.1])

        #expect(frames.map(\.sample) == [0, 1])
    }

    @Test func aVideoWithoutSamplesHasNoFrames() {
        let plan = GIFPlan(times: [0, 0.1], delay: 0.1, width: 80, height: 160)

        #expect(MediaOutputPolicy.gifFrames(plan: plan, sampleTimes: []).isEmpty)
    }

    @Test func theGIFGoesNextToTheSourceWithAFreeName() {
        let taken: Set<String> = ["/tmp/iPhone 2027.gif", "/tmp/iPhone 2027 2.gif"]

        #expect(MediaOutputPolicy.gifPath(for: "/tmp/iPhone 2027.mov", framed: false) { _ in false } == "/tmp/iPhone 2027.gif")
        #expect(MediaOutputPolicy.gifPath(for: "/tmp/iPhone 2027.mov", framed: false) { taken.contains($0) } == "/tmp/iPhone 2027 3.gif")
    }

    @Test func aFramedGIFSaysSoInItsName() {
        #expect(MediaOutputPolicy.gifPath(for: "/tmp/a.mov", framed: true) { _ in false } == "/tmp/a framed.gif")
        #expect(MediaOutputPolicy.gifPath(for: "/tmp/a.mov", framed: true) { $0 == "/tmp/a framed.gif" } == "/tmp/a framed 2.gif")
    }

    @Test func aCompressedVideoNamesItsQuality() {
        #expect(MediaOutputPolicy.compressedPath(for: "/tmp/a.mov", compression: .h264At720p, framed: false) { _ in false } == "/tmp/a 720p.mp4")
        #expect(MediaOutputPolicy.compressedPath(for: "/tmp/a.mov", compression: .hevcAt1080p, framed: false) { $0 == "/tmp/a HEVC 1080p.mp4" } == "/tmp/a HEVC 1080p 2.mp4")
        #expect(MediaOutputPolicy.compressedPath(for: "/tmp/a.mov", compression: .h264At720p, framed: true) { _ in false } == "/tmp/a framed 720p.mp4")
    }

    @Test func eachCompressionHasALongSide() {
        #expect(MediaOutputPolicy.longSide(of: .h264At720p) == 1280)
        #expect(MediaOutputPolicy.longSide(of: .hevcAt1080p) == 1920)
    }

    @Test func onlyVideoFilesCanBeConverted() {
        #expect(MediaOutputPolicy.isVideo("/tmp/a.MOV"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.mp4"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.m4v"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.png") == false)
    }
}
