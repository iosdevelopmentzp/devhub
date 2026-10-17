import AppKit
import SwiftUI

struct ResizeGrip: View {
    @Environment(WindowLayout.self) private var layout

    var body: some View {
        ResizeGripRepresentable(layout: layout)
            .frame(width: 16, height: 16)
            .overlay {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .allowsHitTesting(false)
            }
            .hint("Drag to resize. Double-click to reset the size.")
    }
}

private struct ResizeGripRepresentable: NSViewRepresentable {
    let layout: WindowLayout

    func makeNSView(context: Context) -> GripView {
        GripView(layout: layout)
    }

    func updateNSView(_ view: GripView, context: Context) {}
}

private final class GripView: NSView {
    private let layout: WindowLayout
    private var startMouse = CGPoint.zero
    private var startSize = CGSize.zero
    private var topLeft = CGPoint.zero

    init(layout: WindowLayout) {
        self.layout = layout
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount == 2 {
            layout.setSize(WindowLayout.defaultSize)
            return
        }
        startMouse = NSEvent.mouseLocation
        startSize = window.frame.size
        topLeft = CGPoint(x: window.frame.minX, y: window.frame.maxY)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let visible = window.screen?.visibleFrame else { return }
        let mouse = NSEvent.mouseLocation
        let proposed = CGSize(
            width: startSize.width + mouse.x - startMouse.x,
            height: startSize.height + startMouse.y - mouse.y
        )
        layout.resize(to: proposed, topLeft: topLeft, visibleFrame: visible)
        layout.savePanelTopLeft(topLeft)
        window.setFrame(
            CGRect(x: topLeft.x, y: topLeft.y - layout.size.height, width: layout.size.width, height: layout.size.height),
            display: true
        )
    }
}
