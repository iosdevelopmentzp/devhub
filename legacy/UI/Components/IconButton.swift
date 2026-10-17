import SwiftUI

struct IconButton: View {
    let systemImage: String
    let help: String
    let tint: Tint
    let action: () -> Void

    @State private var isHovering = false

    init(systemImage: String, help: String, tint: Tint = .gray, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(tint.color)
                .frame(width: 24, height: 24)
                .background(isHovering ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .hint(help)
    }
}

#Preview {
    IconButton(systemImage: "trash", help: "Delete", tint: .red) {}
        .padding()
        .previewEnvironment()
}
