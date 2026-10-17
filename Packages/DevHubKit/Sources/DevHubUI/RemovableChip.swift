import SwiftUI

package struct RemovableChip: View {
    private let title: String
    private let systemImage: String
    private let removeHint: String
    private let onRemove: () -> Void

    @State private var isHovered = false

    package init(_ title: String, systemImage: String, removeHint: String, onRemove: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.removeHint = removeHint
        self.onRemove = onRemove
    }

    package var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(isHovered ? 1 : 0.6)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(Color.accentColor)
            .background(Color.accentColor.opacity(isHovered ? 0.2 : 0.12), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .fixedSize()
        .onHover { isHovered = $0 }
        .hint(removeHint)
    }
}

#Preview {
    HStack {
        RemovableChip("target: dev", systemImage: "arrow.triangle.branch", removeHint: "Remove this filter") {}
        RemovableChip("only with conflicts", systemImage: "exclamationmark.triangle", removeHint: "Remove this filter") {}
    }
    .padding()
}
