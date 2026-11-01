import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceFrameRenderer {
    let source: DeviceFrameSource

    var layout: DeviceFrameLayout {
        DeviceFrameLayout.make(chrome: source.chrome, screen: source.screen, compositeSize: source.chrome.composite.flatMap(page).map(size(of:)))
    }

    func render(_ screenshot: CGImage) throws -> CGImage {
        try render(screenshot, scale: source.scale, background: nil)
    }

    func render(_ screenshot: CGImage?, scale: Double, background: CGColor?) throws -> CGImage {
        let composite = source.chrome.composite.flatMap(page)
        let layout = layout
        guard let context = CGContext(
            data: nil,
            width: Int((layout.canvas.width * scale).rounded()),
            height: Int((layout.canvas.height * scale).rounded()),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MediaError.noFrame("DevHub cannot draw an image of this size.")
        }
        context.scaleBy(x: scale, y: scale)
        if let background {
            context.setFillColor(background)
            context.fill(CGRect(origin: .zero, size: layout.canvas))
        }
        drawButtons(onTop: false, layout: layout, context: context)
        if let composite {
            draw(composite, in: layout.body, context: context)
        } else {
            try drawPieces(layout: layout, context: context)
            context.setFillColor(CGColor(gray: 0, alpha: 1))
            context.fill(layout.screen)
        }
        drawButtons(onTop: true, layout: layout, context: context)
        if let screenshot {
            context.draw(screenshot, in: layout.screen)
        } else {
            clearScreen(layout: layout, context: context)
        }
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

    private func clearScreen(layout: DeviceFrameLayout, context: CGContext) {
        let corner = source.chrome.outline.map(layout.screenCorner) ?? .zero
        context.saveGState()
        context.setBlendMode(.clear)
        context.addPath(CGPath(roundedRect: layout.screen, cornerWidth: corner.width, cornerHeight: corner.height, transform: nil))
        context.fillPath()
        context.restoreGState()
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
