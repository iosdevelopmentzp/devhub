import Foundation
import Testing
@testable import DevHubDomain

@Suite struct VideoCompressionPolicyTests {
    @Test(arguments: ["/a/Clip.mov", "/a/clip.MP4", "/a/clip.m4v", "/a/clip.mkv", "/a/clip.webm", "/a/clip.avi"])
    func commonVideoFilesAreVideos(path: String) {
        #expect(VideoCompressionPolicy.isVideo(path))
    }

    @Test(arguments: ["/a/notes.txt", "/a/image.png", "/a/folder", "/a/clip.gif"])
    func otherFilesAreNotVideos(path: String) {
        #expect(VideoCompressionPolicy.isVideo(path) == false)
    }

    @Test func theOutputIsAnMP4NextToTheSource() {
        #expect(VideoCompressionPolicy.outputPath(for: "/Users/alex/Desktop/Screen Recording.mov") { _ in false } == "/Users/alex/Desktop/Screen Recording compressed.mp4")
    }

    @Test func anExistingOutputGetsANumber() {
        let taken: Set<String> = ["/a/clip compressed.mp4", "/a/clip compressed 2.mp4"]

        #expect(VideoCompressionPolicy.outputPath(for: "/a/clip.mp4") { taken.contains($0) } == "/a/clip compressed 3.mp4")
    }

    @Test func thePartialFileIsHiddenInTheSameFolder() {
        #expect(VideoCompressionPolicy.partialPath(for: "/a/clip compressed.mp4", token: "AB12") == "/a/.clip compressed-AB12.mp4")
    }

    @Test func highQualityKeepsTheSize() {
        let size = VideoCompressionPolicy.outputSize(width: 3456, height: 2234, quality: .high)

        #expect(size == (3456, 2234))
    }

    @Test func balancedQualityFitsTheLongSideInto1920() {
        let size = VideoCompressionPolicy.outputSize(width: 3456, height: 2234, quality: .balanced)

        #expect(size == (1920, 1240))
    }

    @Test func smallQualityFitsAPortraitVideoInto1280() {
        let size = VideoCompressionPolicy.outputSize(width: 1206, height: 2622, quality: .small)

        #expect(size == (588, 1280))
    }

    @Test func aSmallVideoIsNotScaledUp() {
        let size = VideoCompressionPolicy.outputSize(width: 800, height: 600, quality: .small)

        #expect(size == (800, 600))
    }

    @Test func oddSidesBecomeEven() {
        let size = VideoCompressionPolicy.outputSize(width: 1001, height: 733, quality: .high)

        #expect(size == (1000, 732))
    }

    @Test func theFractionStaysBetweenZeroAndOne() {
        #expect(VideoCompressionPolicy.fraction(done: 10, duration: 40) == 0.25)
        #expect(VideoCompressionPolicy.fraction(done: 50, duration: 40) == 1)
        #expect(VideoCompressionPolicy.fraction(done: 5, duration: 0) == 0)
    }

    @Test func theRemainingTimeUsesTheSpeed() {
        #expect(VideoCompressionPolicy.remaining(done: 10, duration: 40, speed: 3) == 10)
        #expect(VideoCompressionPolicy.remaining(done: 10, duration: 40, speed: nil) == nil)
        #expect(VideoCompressionPolicy.remaining(done: 10, duration: 40, speed: 0) == nil)
    }

    @Test func theSavingIsTheShareOfTheOriginalSize() {
        #expect(VideoCompressionPolicy.saving(original: 100, compressed: 25) == 0.75)
        #expect(VideoCompressionPolicy.saving(original: 100, compressed: 120) < 0)
        #expect(VideoCompressionPolicy.saving(original: 0, compressed: 10) == 0)
    }
}
