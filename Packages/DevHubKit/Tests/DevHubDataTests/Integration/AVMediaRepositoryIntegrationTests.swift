import AVFoundation
import DevHubDomain
import DevHubTestSupport
import Foundation
import ImageIO
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct AVMediaRepositoryIntegrationTests {
    private let folder: TemporaryDirectory
    private let source: String

    init() async throws {
        folder = try TemporaryDirectory()
        source = folder.path("Recording.mov")
        try await TestVideo.write(to: URL(fileURLWithPath: source), width: 160, height: 320, frames: 20, framesPerSecond: 10)
    }

    @Test func aGIFHasOneFramePerStepAndTheChosenWidth() async throws {
        let progress = CallbackRecorder<Double>()

        let output = try await AVMediaRepository().makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5)) { progress.append($0) }

        #expect(output == folder.path("Recording.gif"))
        let image = try #require(CGImageSourceCreateWithURL(URL(fileURLWithPath: output) as CFURL, nil))
        #expect(CGImageSourceGetCount(image) == 10)
        let first = try #require(CGImageSourceCreateImageAtIndex(image, 0, nil))
        #expect(first.width == 80)
        #expect(first.height == 160)
        #expect(progress.values.last == 1)
    }

    @Test func aSecondGIFDoesNotReplaceTheFirst() async throws {
        let repository = AVMediaRepository()
        _ = try await repository.makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5)) { _ in }

        let second = try await repository.makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5)) { _ in }

        #expect(second == folder.path("Recording 2.gif"))
    }

    @Test func aCompressedVideoIsAnMP4WithAVideoTrack() async throws {
        let output = try await AVMediaRepository().compress(source, as: .h264At720p)

        #expect(output == folder.path("Recording 720p.mp4"))
        let tracks = try await AVURLAsset(url: URL(fileURLWithPath: output)).loadTracks(withMediaType: .video)
        #expect(tracks.count == 1)
    }

    @Test func aFileWithoutVideoFails() async throws {
        let text = try folder.write("not a video", to: "Notes.mov")

        await #expect(throws: (any Error).self) {
            _ = try await AVMediaRepository().makeGIF(from: text.path, options: GIFOptions(width: 80, framesPerSecond: 5)) { _ in }
        }
    }

    @Test func eachCompressionHasAPreset() {
        #expect(AVMediaRepository.preset(for: .h264At720p) == AVAssetExportPreset1280x720)
        #expect(AVMediaRepository.preset(for: .hevcAt1080p) == AVAssetExportPresetHEVC1920x1080)
    }
}

