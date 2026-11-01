import Foundation
import AVFoundation
import QuartzCore
import DevHubDomain

enum FramedVideoComposition {
    static func make(asset: AVURLAsset, track: AVAssetTrack, renderer: DeviceFrameRenderer, longSide: Double) async throws -> AVVideoComposition {
        let layout = renderer.layout
        let size = renderSize(canvas: layout.canvas, scale: renderer.source.scale, longSide: longSide)
        let overlay = try DeviceFrameOverlay(renderer: renderer, scale: size.width / layout.canvas.width)
        let (naturalSize, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
        let duration = try await asset.load(.duration)
        var layer = AVVideoCompositionLayerInstruction.Configuration(assetTrack: track)
        layer.setTransform(transform(naturalSize: naturalSize, preferredTransform: preferredTransform, into: screenFromTop(layout: layout, renderSize: size)), at: .zero)
        let instruction = AVVideoCompositionInstruction(configuration: AVVideoCompositionInstruction.Configuration(
            layerInstructions: [AVVideoCompositionLayerInstruction(configuration: layer)],
            timeRange: CMTimeRange(start: .zero, duration: duration)
        ))
        var configuration = AVVideoComposition.Configuration()
        configuration.animationTool = animationTool(overlay: overlay.image, renderSize: size)
        configuration.frameDuration = CMTime(value: 1, timescale: 30)
        configuration.instructions = [instruction]
        configuration.renderSize = size
        return AVVideoComposition(configuration: configuration)
    }

    static func renderSize(canvas: CGSize, scale: Double, longSide: Double) -> CGSize {
        let fit = min(longSide / max(canvas.width, canvas.height, 1), scale)
        return CGSize(width: even(canvas.width * fit), height: even(canvas.height * fit))
    }

    static func screenFromTop(layout: DeviceFrameLayout, renderSize: CGSize) -> CGRect {
        let scaleX = renderSize.width / layout.canvas.width
        let scaleY = renderSize.height / layout.canvas.height
        return CGRect(
            x: layout.screen.minX * scaleX,
            y: (layout.canvas.height - layout.screen.maxY) * scaleY,
            width: layout.screen.width * scaleX,
            height: layout.screen.height * scaleY
        )
    }

    static func transform(naturalSize: CGSize, preferredTransform: CGAffineTransform, into target: CGRect) -> CGAffineTransform {
        let oriented = CGRect(origin: .zero, size: naturalSize).applying(preferredTransform)
        guard oriented.width > 0, oriented.height > 0 else { return preferredTransform }
        return preferredTransform
            .concatenating(CGAffineTransform(translationX: -oriented.minX, y: -oriented.minY))
            .concatenating(CGAffineTransform(scaleX: target.width / oriented.width, y: target.height / oriented.height))
            .concatenating(CGAffineTransform(translationX: target.minX, y: target.minY))
    }

    private static func animationTool(overlay: CGImage, renderSize: CGSize) -> AVVideoCompositionCoreAnimationTool {
        let bounds = CGRect(origin: .zero, size: renderSize)
        let container = CALayer()
        container.frame = bounds
        let video = CALayer()
        video.frame = bounds
        let frame = CALayer()
        frame.frame = bounds
        frame.contents = overlay
        container.addSublayer(video)
        container.addSublayer(frame)
        return AVVideoCompositionCoreAnimationTool(configuration: AVVideoCompositionCoreAnimationTool.Configuration(postProcessingAsVideoLayer: video, containingLayer: container))
    }

    private static func even(_ value: Double) -> Double {
        max((value / 2).rounded() * 2, 2)
    }
}
