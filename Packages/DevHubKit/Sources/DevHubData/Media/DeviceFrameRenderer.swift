import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceFrameRenderer {
    let source: DeviceFrameSource

    func render(_ screenshot: CGImage) throws -> CGImage {
        let chrome = source.chrome
        let composite = chrome.composite.flatMap(page)
        let layout = DeviceFrameLayout.make(chrome: chrome, screen: source.screen, compositeSize: composite.map { $0.getBoxRect(.mediaBox).size })
        guard let context = CGContext(
            data: nil,
            width: Int((layout.canvas.width * source.scale).rounded()),
            height: Int((layout.canvas.height * source.scale).rounded()),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MediaError.noFrame("DevHub cannot draw an image of this size.")
        }
        context.scaleBy(x: source.scale, y: source.scale)
        drawButtons(onTop: false, layout: layout, context: context)
        if let composite {
            draw(composite, in: layout.body, context: context)
        } else {
            try drawPieces(layout: layout, context: context)
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fill(layout.screen)
        }
        drawButtons(onTop: true, layout: layout, context: context)
        context.draw(screenshot, in: layout.screen)
        guard let image = context.makeImage() else {
            throw MediaError.noFrame("DevHub cannot draw the frame.")
        }
        return image
    }

    private func drawPieces(layout: DeviceFrameLayout, context: CGContext) throws {
        let pieces = source.chrome.pieces
        let body = layout.body
        let topLeft = try piece(pieces.topLeft)
        let topRight = try piece(pieces.topRight)
        let bottomLeft = try piece(pieces.bottomLeft)
        let bottomRight = try piece(pieces.bottomRight)
        let top = try piece(pieces.top)
        let bottom = try piece(pieces.bottom)
        let left = try piece(pieces.left)
        let right = try piece(pieces.right)
        let topLeftSize = size(of: topLeft)
        let topRightSize = size(of: topRight)
        let bottomLeftSize = size(of: bottomLeft)
        let bottomRightSize = size(of: bottomRight)
        draw(bottomLeft, in: CGRect(origin: CGPoint(x: body.minX, y: body.minY), size: bottomLeftSize), context: context)
        draw(bottomRight, in: CGRect(origin: CGPoint(x: body.maxX - bottomRightSize.width, y: body.minY), size: bottomRightSize), context: context)
        draw(topLeft, in: CGRect(origin: CGPoint(x: body.minX, y: body.maxY - topLeftSize.height), size: topLeftSize), context: context)
        draw(topRight, in: CGRect(origin: CGPoint(x: body.maxX - topRightSize.width, y: body.maxY - topRightSize.height), size: topRightSize), context: context)
        draw(top, in: CGRect(x: body.minX + topLeftSize.width, y: body.maxY - size(of: top).height, width: body.width - topLeftSize.width - topRightSize.width, height: size(of: top).height), context: context)
        draw(bottom, in: CGRect(x: body.minX + bottomLeftSize.width, y: body.minY, width: body.width - bottomLeftSize.width - bottomRightSize.width, height: size(of: bottom).height), context: context)
        draw(left, in: CGRect(x: body.minX, y: body.minY + bottomLeftSize.height, width: size(of: left).width, height: body.height - bottomLeftSize.height - topLeftSize.height), context: context)
        draw(right, in: CGRect(x: body.maxX - size(of: right).width, y: body.minY + bottomRightSize.height, width: size(of: right).width, height: body.height - bottomRightSize.height - topRightSize.height), context: context)
    }

    private func drawButtons(onTop: Bool, layout: DeviceFrameLayout, context: CGContext) {
        for button in source.chrome.buttons where button.onTop == onTop {
            guard let image = page(button.image) else { continue }
            draw(image, in: layout.rect(of: button, size: size(of: image)), context: context)
        }
    }

    private func draw(_ page: CGPDFPage, in rect: CGRect, context: CGContext) {
        let box = page.getBoxRect(.mediaBox)
        guard box.width > 0, box.height > 0 else { return }
        context.saveGState()
        context.clip(to: rect)
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: rect.width / box.width, y: rect.height / box.height)
        context.translateBy(x: -box.minX, y: -box.minY)
        context.drawPDFPage(page)
        context.restoreGState()
    }

    private func piece(_ name: String) throws -> CGPDFPage {
        guard let page = page(name) else {
            throw MediaError.noFrame("the frame part \(name) is missing.")
        }
        return page
    }

    private func page(_ name: String) -> CGPDFPage? {
        CGPDFDocument(source.folder.appendingPathComponent(name + ".pdf") as CFURL)?.page(at: 1)
    }

    private func size(of page: CGPDFPage) -> CGSize {
        page.getBoxRect(.mediaBox).size
    }
}
