import SwiftUI

package struct IconButton: View {
    package let systemImage: String
    package let help: String
    package var tint: Color = .primary
    package let action: () -> Void

    @State private var isHovered = false

    package static let side: CGFloat = 24

    package init(systemImage: String, help: String, tint: Color = .primary, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.tint = tint
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? tint : Color.secondary)
                .frame(width: Self.side, height: Self.side)
                .background(Color.primary.opacity(isHovered ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .hint(help)
    }
}
