import AppKit
import SwiftUI

struct WindowDragArea: NSViewRepresentable {
    let onMoveEnd: (CGPoint) -> Void
    let onDoubleClick: () -> Void

    func makeNSView(context: Context) -> DragView {
        DragView()
    }

    func updateNSView(_ view: DragView, context: Context) {
        view.onMoveEnd = onMoveEnd
        view.onDoubleClick = onDoubleClick
    }
}

final class DragView: NSView {
    var onMoveEnd: (CGPoint) -> Void = { _ in }
    var onDoubleClick: () -> Void = {}

    private var startMouse = CGPoint.zero
    private var startOrigin = CGPoint.zero

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount == 2 {
            onDoubleClick()
            return
        }
        startMouse = NSEvent.mouseLocation
        startOrigin = window.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window else { return }
        let mouse = NSEvent.mouseLocation
        var origin = CGPoint(x: startOrigin.x + mouse.x - startMouse.x, y: startOrigin.y + mouse.y - startMouse.y)
        if let area = window.screen?.visibleFrame.insetBy(dx: WindowLayout.margin, dy: WindowLayout.margin) {
            origin.x = min(max(origin.x, area.minX), max(area.minX, area.maxX - window.frame.width))
            origin.y = min(max(origin.y, area.minY), max(area.minY, area.maxY - window.frame.height))
        }
        window.setFrameOrigin(origin)
    }

    override func mouseUp(with event: NSEvent) {
        guard let window, event.clickCount < 2 else { return }
        onMoveEnd(CGPoint(x: window.frame.minX, y: window.frame.maxY))
    }
}
