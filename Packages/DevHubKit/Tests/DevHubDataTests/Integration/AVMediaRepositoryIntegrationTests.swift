import AVFoundation
import DevHubDomain
import DevHubTestSupport
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import DevHubData

@Suite(.tags(.integration)) struct AVMediaRepositoryIntegrationTests {
    private let folder: TemporaryDirectory
    private let source: String

    private var repository: AVMediaRepository {
        AVMediaRepository(chromes: DeviceChromeLocator(devicesRoot: folder.url, deviceTypeRoots: [], chromeRoot: folder.url))
    }

    init() async throws {
        folder = try TemporaryDirectory()
        source = folder.path("Recording.mov")
        try await TestVideo.write(to: URL(fileURLWithPath: source), width: 160, height: 320, frames: 20, framesPerSecond: 10)
    }

    @Test func aGIFHasOneFramePerStepAndTheChosenWidth() async throws {
        let progress = CallbackRecorder<Double>()

        let output = try await repository.makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5), framedFor: nil) { progress.append($0) }

        #expect(output == folder.path("Recording.gif"))
        let image = try #require(CGImageSourceCreateWithURL(URL(fileURLWithPath: output) as CFURL, nil))
        #expect(CGImageSourceGetCount(image) == 10)
        let first = try #require(CGImageSourceCreateImageAtIndex(image, 0, nil))
        #expect(first.width == 80)
        #expect(first.height == 160)
        #expect(progress.values.last == 1)
    }

    @Test func theSampleTimesAreEveryFrameOfTheVideoInOrder() async throws {
        let asset = AVURLAsset(url: URL(fileURLWithPath: source))
        let track = try #require(try await asset.loadTracks(withMediaType: .video).first)

        let times = try #require(AVMediaRepository.sampleTimes(of: track, in: asset))

        #expect(times.count == 20)
        #expect(times.first == .zero)
        #expect(times == times.sorted())
    }

    @Test func aSecondGIFDoesNotReplaceTheFirst() async throws {
        _ = try await repository.makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5), framedFor: nil) { _ in }

        let second = try await repository.makeGIF(from: source, options: GIFOptions(width: 80, framesPerSecond: 5), framedFor: nil) { _ in }

        #expect(second == folder.path("Recording 2.gif"))
    }

    @Test func aCompressedVideoIsAnMP4WithAVideoTrack() async throws {
        let output = try await repository.compress(source, as: .h264At720p, framedFor: nil)

        #expect(output == folder.path("Recording 720p.mp4"))
        let tracks = try await AVURLAsset(url: URL(fileURLWithPath: output)).loadTracks(withMediaType: .video)
        #expect(tracks.count == 1)
    }

    @Test func aFileWithoutVideoFails() async throws {
        let text = try folder.write("not a video", to: "Notes.mov")

        await #expect(throws: (any Error).self) {
            _ = try await repository.makeGIF(from: text.path, options: GIFOptions(width: 80, framesPerSecond: 5), framedFor: nil) { _ in }
        }
    }

    @Test func eachCompressionHasAPreset() {
        #expect(AVMediaRepository.preset(for: .h264At720p) == AVAssetExportPreset1280x720)
        #expect(AVMediaRepository.preset(for: .hevcAt1080p) == AVAssetExportPresetHEVC1920x1080)
    }

    @Test func aFramedScreenshotReplacesThePlainOne() async throws {
        let tree = DeviceChromeTree(directory: folder)
        try tree.makeDevice()
        try tree.makeChrome()
        let screenshot = folder.path("Shot.png")
        try writeImage(width: 200, height: 400, to: screenshot)

        try await AVMediaRepository(chromes: tree.locator).addFrame(to: screenshot, udid: DeviceChromeTree.udid)

        let image = try #require(CGImageSourceCreateWithURL(URL(fileURLWithPath: screenshot) as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) })
        #expect(image.width == 240)
        #expect(image.height == 440)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: folder.url.path).filter { $0.hasPrefix(".") }
        #expect(leftovers.isEmpty)
    }

    @Test func aScreenshotOfAnUnknownDeviceStaysAsItIs() async throws {
        let screenshot = folder.path("Shot.png")
        try writeImage(width: 200, height: 400, to: screenshot)

        await #expect(throws: MediaError.self) {
            try await repository.addFrame(to: screenshot, udid: "OTHER")
        }
        let image = try #require(CGImageSourceCreateWithURL(URL(fileURLWithPath: screenshot) as CFURL, nil).flatMap { CGImageSourceCreateImageAtIndex($0, 0, nil) })
        #expect(image.width == 200)
    }

    @Test func aFramedGIFHasTheSizeOfTheFrame() async throws {
        let tree = DeviceChromeTree(directory: folder)
        try tree.makeDevice()
        try tree.makeChrome()

        let output = try await AVMediaRepository(chromes: tree.locator).makeGIF(from: source, options: GIFOptions(width: 120, framesPerSecond: 5), framedFor: DeviceChromeTree.udid) { _ in }

        #expect(output == folder.path("Recording framed.gif"))
        let image = try #require(CGImageSourceCreateWithURL(URL(fileURLWithPath: output) as CFURL, nil))
        #expect(CGImageSourceGetCount(image) == 10)
        let first = try #require(CGImageSourceCreateImageAtIndex(image, 0, nil))
        #expect(first.width == 120)
        #expect(first.height == 220)
    }

    @Test func aFramedVideoHasTheSizeOfTheFrame() async throws {
        let tree = DeviceChromeTree(directory: folder)
        try tree.makeDevice()
        try tree.makeChrome()

        let output = try await AVMediaRepository(chromes: tree.locator).compress(source, as: .h264At720p, framedFor: DeviceChromeTree.udid)

        #expect(output == folder.path("Recording framed 720p.mp4"))
        let track = try #require(try await AVURLAsset(url: URL(fileURLWithPath: output)).loadTracks(withMediaType: .video).first)
        #expect(try await track.load(.naturalSize) == CGSize(width: 240, height: 440))
    }

    @Test func aFramedVideoOfAnUnknownDeviceFailsWithoutAFile() async throws {
        await #expect(throws: MediaError.self) {
            _ = try await repository.compress(source, as: .h264At720p, framedFor: "OTHER")
        }
        #expect(FileManager.default.fileExists(atPath: folder.path("Recording framed 720p.mp4")) == false)
    }

    private func writeImage(width: Int, height: Int, to path: String) throws {
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(red: 0, green: 0.5, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let output = try #require(CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(output, image, nil)
        #expect(CGImageDestinationFinalize(output))
    }
}

