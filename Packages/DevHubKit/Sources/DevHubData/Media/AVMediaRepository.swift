import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import DevHubDomain

struct AVMediaRepository: MediaRepository {
    let chromes: DeviceChromeLocator

    func makeGIF(from source: String, options: GIFOptions, framedFor udid: String?, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String {
        let destination = MediaOutputPolicy.gifPath(for: source, framed: udid != nil, exists: FileManager.default.fileExists(atPath:))
        let asset = AVURLAsset(url: URL(fileURLWithPath: source))
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaError.noVideo(source)
        }
        let (naturalSize, transform) = try await track.load(.naturalSize, .preferredTransform)
        let size = naturalSize.applying(transform)
        let duration = try await asset.load(.duration).seconds
        let renderer = try udid.map { DeviceFrameRenderer(source: try chromes.source(udid: $0)) }
        let natural = renderer.map { CGSize(width: $0.layout.canvas.width * $0.source.scale, height: $0.layout.canvas.height * $0.source.scale) }
            ?? CGSize(width: abs(size.width), height: abs(size.height))
        let plan = MediaOutputPolicy.gifPlan(duration: duration, naturalWidth: natural.width, naturalHeight: natural.height, options: options)
        let samples = Self.sampleTimes(of: track, in: asset) ?? plan.times.map { CMTime(seconds: $0, preferredTimescale: 600) }
        let frames = MediaOutputPolicy.gifFrames(plan: plan, sampleTimes: samples.map(\.seconds))
        let overlay = try renderer.map { try DeviceFrameOverlay(renderer: $0, scale: Double(plan.width) / $0.layout.canvas.width) }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = overlay?.screen.size ?? CGSize(width: plan.width, height: plan.height)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let data = NSMutableData()
        guard let output = CGImageDestinationCreateWithData(data as CFMutableData, UTType.gif.identifier as CFString, frames.count, nil) else {
            throw MediaError.cannotWrite(destination)
        }
        CGImageDestinationSetProperties(output, Self.fileProperties)
        var written = 0
        for await result in generator.images(for: frames.map { samples[$0.sample] }) {
            try Task.checkCancellation()
            let image = try result.image
            CGImageDestinationAddImage(output, try overlay?.drawing(image) ?? image, Self.frameProperties(delay: frames[written].delay))
            written += 1
            onProgress(Double(written) / Double(frames.count))
        }
        try Task.checkCancellation()
        guard written > 0, CGImageDestinationFinalize(output) else {
            throw MediaError.cannotWrite(destination)
        }
        do {
            try data.write(to: URL(fileURLWithPath: destination), options: .atomic)
        } catch {
            throw MediaError.cannotWrite(destination)
        }
        return destination
    }

    func compress(_ source: String, as compression: VideoCompression, framedFor udid: String?) async throws -> String {
        let destination = MediaOutputPolicy.compressedPath(for: source, compression: compression, framed: udid != nil, exists: FileManager.default.fileExists(atPath:))
        let asset = AVURLAsset(url: URL(fileURLWithPath: source))
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaError.noVideo(source)
        }
        guard let session = AVAssetExportSession(asset: asset, presetName: Self.preset(for: compression)) else {
            throw MediaError.exportFailed("this Mac cannot export with the preset \(Self.preset(for: compression)).")
        }
        if let udid {
            let renderer = DeviceFrameRenderer(source: try chromes.source(udid: udid))
            session.videoComposition = try await FramedVideoComposition.make(asset: asset, track: track, renderer: renderer, longSide: MediaOutputPolicy.longSide(of: compression))
        }
        do {
            try await session.export(to: URL(fileURLWithPath: destination), as: .mp4)
            return destination
        } catch {
            try? FileManager.default.removeItem(atPath: destination)
            if error is CancellationError || Task.isCancelled {
                throw CancellationError()
            }
            throw MediaError.exportFailed(error.localizedDescription)
        }
    }

    func addFrame(to screenshot: String, udid: String) async throws {
        let source = try chromes.source(udid: udid)
        let url = URL(fileURLWithPath: screenshot)
        guard let input = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(input, 0, nil) else {
            throw MediaError.cannotRead(screenshot)
        }
        let framed = try DeviceFrameRenderer(source: source).render(image)
        let temporary = url.deletingLastPathComponent().appendingPathComponent(".\(UUID().uuidString).png")
        guard let output = CGImageDestinationCreateWithURL(temporary as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw MediaError.cannotWrite(screenshot)
        }
        CGImageDestinationAddImage(output, framed, nil)
        guard CGImageDestinationFinalize(output) else {
            try? FileManager.default.removeItem(at: temporary)
            throw MediaError.cannotWrite(screenshot)
        }
        _ = try FileManager.default.replaceItemAt(url, withItemAt: temporary)
    }

    static func sampleTimes(of track: AVAssetTrack, in asset: AVAsset) -> [CMTime]? {
        guard let reader = try? AVAssetReader(asset: asset) else { return nil }
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return nil }
        reader.add(output)
        guard reader.startReading() else { return nil }
        var times: [CMTime] = []
        while let buffer = output.copyNextSampleBuffer() {
            guard CMSampleBufferGetNumSamples(buffer) > 0 else { continue }
            times.append(CMSampleBufferGetPresentationTimeStamp(buffer))
        }
        let sorted = times.filter(\.isNumeric).sorted()
        guard reader.status == .completed, sorted.isEmpty == false else { return nil }
        return sorted
    }

    static func preset(for compression: VideoCompression) -> String {
        switch compression {
        case .h264At720p: AVAssetExportPreset1280x720
        case .hevcAt1080p: AVAssetExportPresetHEVC1920x1080
        }
    }

    private static var fileProperties: CFDictionary {
        [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary
    }

    private static func frameProperties(delay: Double) -> CFDictionary {
        [kCGImagePropertyGIFDictionary as String: [
            kCGImagePropertyGIFDelayTime as String: delay,
            kCGImagePropertyGIFUnclampedDelayTime as String: delay,
        ]] as CFDictionary
    }
}
