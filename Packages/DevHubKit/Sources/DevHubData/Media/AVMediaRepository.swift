import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import DevHubDomain

struct AVMediaRepository: MediaRepository {
    func makeGIF(from source: String, options: GIFOptions, onProgress: @escaping @Sendable (Double) -> Void) async throws -> String {
        let destination = MediaOutputPolicy.gifPath(for: source, exists: FileManager.default.fileExists(atPath:))
        let asset = AVURLAsset(url: URL(fileURLWithPath: source))
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw MediaError.noVideo(source)
        }
        let (naturalSize, transform) = try await track.load(.naturalSize, .preferredTransform)
        let size = naturalSize.applying(transform)
        let duration = try await asset.load(.duration).seconds
        let plan = MediaOutputPolicy.gifPlan(duration: duration, naturalWidth: abs(size.width), naturalHeight: abs(size.height), options: options)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: plan.width, height: plan.height)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        guard let output = CGImageDestinationCreateWithURL(URL(fileURLWithPath: destination) as CFURL, UTType.gif.identifier as CFString, plan.times.count, nil) else {
            throw MediaError.cannotWrite(destination)
        }
        CGImageDestinationSetProperties(output, Self.fileProperties)
        let frame = Self.frameProperties(delay: plan.delay)
        var written = 0
        for await result in generator.images(for: plan.times.map { CMTime(seconds: $0, preferredTimescale: 600) }) {
            try Task.checkCancellation()
            CGImageDestinationAddImage(output, try result.image, frame)
            written += 1
            onProgress(Double(written) / Double(plan.times.count))
        }
        try Task.checkCancellation()
        guard written > 0, CGImageDestinationFinalize(output) else {
            throw MediaError.cannotWrite(destination)
        }
        return destination
    }

    func compress(_ source: String, as compression: VideoCompression) async throws -> String {
        let destination = MediaOutputPolicy.compressedPath(for: source, compression: compression, exists: FileManager.default.fileExists(atPath:))
        let asset = AVURLAsset(url: URL(fileURLWithPath: source))
        guard try await asset.loadTracks(withMediaType: .video).isEmpty == false else {
            throw MediaError.noVideo(source)
        }
        guard let session = AVAssetExportSession(asset: asset, presetName: Self.preset(for: compression)) else {
            throw MediaError.exportFailed("this Mac cannot export with the preset \(Self.preset(for: compression)).")
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
