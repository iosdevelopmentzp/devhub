import AppKit
import SwiftUI
import DevHubDomain
import DevHubUI

struct ResizeGrip: View {
    @Environment(WindowLayout.self) private var layout

    @State private var start: (mouse: CGPoint, size: CGSize)?
    @State private var isHovered = false
    @State private var window: NSWindow?

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isHovered || start != nil ? Color.primary : .secondary)
            .frame(width: 22, height: 22)
            .background(Color.primary.opacity(isHovered || start != nil ? 0.08 : 0), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        let mouse = NSEvent.mouseLocation
                        if start == nil {
                            start = (mouse, layout.size)
                        }
                        guard let start else { return }
                        layout.resize(
                            to: CGSize(
                                width: start.size.width + mouse.x - start.mouse.x,
                                height: start.size.height + start.mouse.y - mouse.y
                            ),
                            in: window
                        )
                    }
                    .onEnded { _ in start = nil }
            )
            .onTapGesture(count: 2) {
                layout.reset()
                if let window {
                    layout.fit(window)
                }
            }
            .background(HostWindowReader { window = $0 })
            .hint("Drag to resize the panel. Double-click for the default size. The size is remembered.")
    }

}
