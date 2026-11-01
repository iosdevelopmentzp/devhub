import AVFoundation
import CoreVideo
import Foundation

enum TestVideo {
    static func write(to url: URL, width: Int, height: Int, frames: Int, framesPerSecond: Int32) async throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
        ])
        input.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: nil)
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        for index in 0..<frames {
            while input.isReadyForMoreMediaData == false {
                await Task.yield()
            }
            adaptor.append(try frame(width: width, height: height, shade: UInt8(index * 255 / max(frames - 1, 1))), withPresentationTime: CMTime(value: CMTimeValue(index), timescale: framesPerSecond))
        }
        input.markAsFinished()
        await writer.finishWriting()
    }

    private static func frame(width: Int, height: Int, shade: UInt8) throws -> CVPixelBuffer {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, width, height, kCVPixelFormatType_32ARGB, nil, &buffer)
        guard let buffer else { throw CocoaError(.fileWriteUnknown) }
        CVPixelBufferLockBaseAddress(buffer, [])
        memset(CVPixelBufferGetBaseAddress(buffer), Int32(shade), CVPixelBufferGetDataSize(buffer))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
