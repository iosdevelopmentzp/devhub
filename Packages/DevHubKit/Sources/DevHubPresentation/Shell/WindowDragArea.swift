import AppKit
import SwiftUI
import DevHubDomain
import DevHubUI

struct WindowDragArea: NSViewRepresentable {
    let onMoved: (NSWindow) -> Void
    let onDoubleClick: () -> Void

    func makeNSView(context: Context) -> DragView {
        let view = DragView()
        view.onMoved = onMoved
        view.onDoubleClick = onDoubleClick
        return view
    }

    func updateNSView(_ view: DragView, context: Context) {
        view.onMoved = onMoved
        view.onDoubleClick = onDoubleClick
    }

    final class DragView: NSView {
        var onMoved: ((NSWindow) -> Void)?
        var onDoubleClick: (() -> Void)?

        private var dragStart: (mouse: CGPoint, origin: CGPoint)?

        override var mouseDownCanMoveWindow: Bool { false }

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            if event.clickCount == 2 {
                onDoubleClick?()
                return
            }
            dragStart = (NSEvent.mouseLocation, window.frame.origin)
        }

        override func mouseDragged(with event: NSEvent) {
            guard let window, let dragStart else { return }
            let mouse = NSEvent.mouseLocation
            var origin = CGPoint(
                x: dragStart.origin.x + mouse.x - dragStart.mouse.x,
                y: dragStart.origin.y + mouse.y - dragStart.mouse.y
            )
            let size = window.frame.size
            if let area = WindowLayout.usableArea(of: WindowLayout.screen(containing: mouse)), size.width <= area.width, size.height <= area.height {
                origin.x = min(max(origin.x, area.minX), area.maxX - size.width)
                origin.y = min(max(origin.y, area.minY), area.maxY - size.height)
            }
            window.setFrameOrigin(origin)
        }

        override func mouseUp(with event: NSEvent) {
            defer { dragStart = nil }
            guard let window, let dragStart, window.frame.origin != dragStart.origin else { return }
            onMoved?(window)
        }
    }
}
