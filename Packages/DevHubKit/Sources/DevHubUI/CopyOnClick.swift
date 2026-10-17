import SwiftUI

package struct CopyOnClick: ViewModifier {
    @Environment(\.copyToPasteboard) private var copyToPasteboard

    package let value: String
    package let label: String

    @State private var isHovered = false

    package init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    package func body(content: Content) -> some View {
        content
            .underline(isHovered, color: Color.secondary.opacity(0.5))
            .contentShape(Rectangle())
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            .onTapGesture {
                copyToPasteboard(value, label)
            }
            .hintWhenTruncated(value, adding: "Click to copy")
    }
}
