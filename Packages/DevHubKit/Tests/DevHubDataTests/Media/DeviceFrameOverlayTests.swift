import CoreGraphics
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct DeviceFrameOverlayTests {
    private let folder: TemporaryDirectory
    private let renderer: DeviceFrameRenderer

    init() throws {
        folder = try TemporaryDirectory()
        let tree = DeviceChromeTree(directory: folder)
        try tree.makeDevice()
        try tree.makeChrome()
        renderer = DeviceFrameRenderer(source: try tree.locator.source(udid: DeviceChromeTree.udid))
    }

    @Test func theScreenIsAnEmptyHoleInTheScaledFrame() throws {
        let overlay = try DeviceFrameOverlay(renderer: renderer, scale: 0.5)

        #expect(overlay.image.width == 60)
        #expect(overlay.image.height == 110)
        #expect(overlay.screen == CGRect(x: 5, y: 5, width: 50, height: 100))
        #expect(try pixel(of: overlay.image, x: 30, y: 55)[3] == 0)
    }

    @Test func aFrameShowsOnlyInsideTheScreen() throws {
        let overlay = try DeviceFrameOverlay(renderer: renderer, scale: 1)

        let framed = try overlay.drawing(try blueImage(width: 100, height: 200))

        let inside = try pixel(of: framed, x: 60, y: 110)
        let outside = try pixel(of: framed, x: 2, y: 2)
        #expect(inside[2] > 200 && inside[0] < 40)
        #expect(outside[0] == outside[2] && outside[0] < 120 && outside[3] == 255)
    }

    @Test func theScreenHoleHasRoundCorners() throws {
        let overlay = try DeviceFrameOverlay(renderer: renderer, scale: 1)

        #expect(try pixel(of: overlay.image, x: 10, y: 10)[3] == 255)
        #expect(try pixel(of: overlay.image, x: 109, y: 209)[3] == 255)
        #expect(try pixel(of: overlay.image, x: 30, y: 30)[3] == 0)
    }

    private func blueImage(width: Int, height: Int) throws -> CGImage {
        let context = try #require(CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try #require(context.makeImage())
    }

    private func pixel(of image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let context = try #require(CGContext(data: &bytes, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let start = (y * image.width + x) * 4
        return Array(bytes[start..<start + 4])
    }
}
