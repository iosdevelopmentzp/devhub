import SwiftUI

package struct HoverActions<Content: View>: View {
    package let isVisible: Bool
    package let count: Int
    package let spacing: CGFloat
    private let content: Content

    package init(isVisible: Bool, count: Int, spacing: CGFloat, @ViewBuilder content: () -> Content) {
        self.isVisible = isVisible
        self.count = count
        self.spacing = spacing
        self.content = content()
    }

    package var body: some View {
        if isVisible {
            HStack(spacing: spacing) {
                content
            }
        } else {
            Color.clear
                .frame(width: placeholderWidth, height: IconButton.side)
        }
    }

    private var placeholderWidth: CGFloat {
        CGFloat(count) * IconButton.side + spacing * CGFloat(max(count - 1, 0))
    }
}
