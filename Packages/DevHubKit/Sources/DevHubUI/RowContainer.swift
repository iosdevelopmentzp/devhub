import SwiftUI

package struct RowContainer<Content: View>: View {
    private let verticalPadding: CGFloat
    private let isHighlighted: Bool
    private let highlight: Color
    private let content: (_ isHovered: Bool) -> Content

    @State private var isHovered = false

    package init(
        verticalPadding: CGFloat = 8,
        isHighlighted: Bool = false,
        highlight: Color = Color.accentColor.opacity(0.08),
        @ViewBuilder content: @escaping (_ isHovered: Bool) -> Content
    ) {
        self.verticalPadding = verticalPadding
        self.isHighlighted = isHighlighted
        self.highlight = highlight
        self.content = content
    }

    package var body: some View {
        content(isHovered)
            .padding(.horizontal, 14)
            .padding(.vertical, verticalPadding)
            .background(background)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
    }

    private var background: Color {
        if isHighlighted { return highlight }
        return isHovered ? Theme.hover : .clear
    }
}

#Preview {
    VStack(spacing: 0) {
        RowContainer { isHovered in
            HStack {
                Text("Hover this row")
                Spacer()
                IconButton(systemImage: "trash", help: "Delete", tint: .red) {}
                    .opacity(isHovered ? 1 : 0)
            }
        }
        Divider()
        RowContainer(verticalPadding: 7, isHighlighted: true) { _ in
            Text("Highlighted row")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .frame(width: 400)
    .background(Theme.surface)
}
