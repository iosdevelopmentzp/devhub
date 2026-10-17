import AppKit
import SwiftUI

package struct SplitHandle: View {
    private let onDrag: (_ translation: CGFloat) -> Void
    private let onEnd: () -> Void

    @State private var isHovered = false

    package init(onDrag: @escaping (_ translation: CGFloat) -> Void, onEnd: @escaping () -> Void) {
        self.onDrag = onDrag
        self.onEnd = onEnd
    }

    package var body: some View {
        Rectangle()
            .fill(isHovered ? Color.accentColor.opacity(0.5) : Theme.border)
            .frame(width: isHovered ? 2 : 1)
            .frame(width: 9)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { onDrag($0.translation.width) }
                    .onEnded { _ in onEnd() }
            )
    }
}

#Preview {
    HStack(spacing: 0) {
        Color.white
        SplitHandle(onDrag: { _ in }, onEnd: {})
        Color.white
    }
    .frame(width: 400, height: 200)
}
