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

    @Test func theGIFGoesNextToTheSourceWithAFreeName() {
        let taken: Set<String> = ["/tmp/iPhone 2027.gif", "/tmp/iPhone 2027 2.gif"]

        #expect(MediaOutputPolicy.gifPath(for: "/tmp/iPhone 2027.mov") { _ in false } == "/tmp/iPhone 2027.gif")
        #expect(MediaOutputPolicy.gifPath(for: "/tmp/iPhone 2027.mov") { taken.contains($0) } == "/tmp/iPhone 2027 3.gif")
    }

    @Test func aCompressedVideoNamesItsQuality() {
        #expect(MediaOutputPolicy.compressedPath(for: "/tmp/a.mov", compression: .h264At720p) { _ in false } == "/tmp/a 720p.mp4")
        #expect(MediaOutputPolicy.compressedPath(for: "/tmp/a.mov", compression: .hevcAt1080p) { $0 == "/tmp/a HEVC 1080p.mp4" } == "/tmp/a HEVC 1080p 2.mp4")
    }

    @Test func onlyVideoFilesCanBeConverted() {
        #expect(MediaOutputPolicy.isVideo("/tmp/a.MOV"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.mp4"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.m4v"))
        #expect(MediaOutputPolicy.isVideo("/tmp/a.png") == false)
    }
}
