import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceFrameOverlay {
    let image: CGImage
    let screen: CGRect

    init(renderer: DeviceFrameRenderer, scale: Double) throws {
        image = try renderer.render(nil, scale: scale, background: CGColor(gray: 1, alpha: 1))
        let screen = renderer.layout.screen
        self.screen = CGRect(x: screen.minX * scale, y: screen.minY * scale, width: screen.width * scale, height: screen.height * scale)
    }

    func drawing(_ frame: CGImage) throws -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MediaError.noFrame("DevHub cannot draw an image of this size.")
        }
        context.draw(frame, in: screen)
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let framed = context.makeImage() else {
            throw MediaError.noFrame("DevHub cannot draw the frame.")
        }
        return framed
    }
}
