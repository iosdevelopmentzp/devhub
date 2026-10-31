import AppKit
import SwiftUI

package struct SplitHandle: View {
    private let axis: Axis
    private let onDrag: (_ translation: CGFloat) -> Void
    private let onEnd: () -> Void

    @State private var isHovered = false

    package init(axis: Axis, onDrag: @escaping (_ translation: CGFloat) -> Void, onEnd: @escaping () -> Void) {
        self.axis = axis
        self.onDrag = onDrag
        self.onEnd = onEnd
    }

    package var body: some View {
        Rectangle()
            .fill(isHovered ? Color.accentColor.opacity(0.5) : Theme.border)
            .frame(width: axis == .vertical ? lineThickness : nil, height: axis == .horizontal ? lineThickness : nil)
            .frame(width: axis == .vertical ? 9 : nil, height: axis == .horizontal ? 9 : nil)
            .frame(maxWidth: axis == .horizontal ? .infinity : nil, maxHeight: axis == .vertical ? .infinity : nil)
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    cursor.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { onDrag(axis == .vertical ? $0.translation.width : $0.translation.height) }
                    .onEnded { _ in onEnd() }
            )
    }

    private var lineThickness: CGFloat {
        isHovered ? 2 : 1
    }

    private var cursor: NSCursor {
        axis == .vertical ? .resizeLeftRight : .resizeUpDown
    }
}

#Preview {
    VStack(spacing: 0) {
        HStack(spacing: 0) {
            Color.white
            SplitHandle(axis: .vertical, onDrag: { _ in }, onEnd: {})
            Color.white
        }
        SplitHandle(axis: .horizontal, onDrag: { _ in }, onEnd: {})
        Color.white
    }
    .frame(width: 400, height: 300)
}
