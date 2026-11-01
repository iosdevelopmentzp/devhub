import Foundation
import CoreGraphics
import DevHubDomain

struct DeviceFrameLayout: Equatable {
    var canvas: CGSize
    var body: CGRect
    var screen: CGRect

    static func make(chrome: DeviceChrome, screen: CGSize, compositeSize: CGSize?) -> DeviceFrameLayout {
        let padding = chrome.padding
        let bodySize = compositeSize ?? CGSize(
            width: screen.width + chrome.sizing.left + chrome.sizing.right,
            height: screen.height + chrome.sizing.top + chrome.sizing.bottom
        )
        let body = CGRect(origin: CGPoint(x: padding.left, y: padding.bottom), size: bodySize)
        let inset = compositeSize.map { CGPoint(x: ($0.width - screen.width) / 2, y: ($0.height - screen.height) / 2) }
            ?? CGPoint(x: chrome.sizing.left, y: chrome.sizing.bottom)
        return DeviceFrameLayout(
            canvas: CGSize(width: bodySize.width + padding.left + padding.right, height: bodySize.height + padding.top + padding.bottom),
            body: body,
            screen: CGRect(origin: CGPoint(x: body.minX + inset.x, y: body.minY + inset.y), size: screen)
        )
    }

    func rect(of button: DeviceChrome.Button, size: CGSize) -> CGRect {
        let x: Double
        let fromTop: Double
        switch button.anchor {
        case "right":
            x = body.width + button.x
            fromTop = position(size.height, in: body.height, offset: button.y, align: button.align)
        case "top":
            x = position(size.width, in: body.width, offset: button.x, align: button.align)
            fromTop = button.y - size.height
        case "bottom":
            x = position(size.width, in: body.width, offset: button.x, align: button.align)
            fromTop = body.height - button.y
        default:
            x = button.x - size.width
            fromTop = position(size.height, in: body.height, offset: button.y, align: button.align)
        }
        return CGRect(x: body.minX + x, y: body.minY + body.height - fromTop - size.height, width: size.width, height: size.height)
    }

    private func position(_ length: Double, in total: Double, offset: Double, align: String) -> Double {
        switch align {
        case "trailing": total + offset - length
        case "center": (total - length) / 2 + offset
        default: offset
        }
    }
}
