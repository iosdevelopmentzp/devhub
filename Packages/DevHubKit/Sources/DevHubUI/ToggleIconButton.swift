import SwiftUI

package struct ToggleIconButton: View {
    package let systemImage: String
    package let help: String
    package let isOn: Bool
    package let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    package init(systemImage: String, help: String, isOn: Bool, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.isOn = isOn
        self.action = action
    }

    package var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: isOn ? .semibold : .medium))
                .foregroundStyle(foreground)
                .frame(width: IconButton.side, height: IconButton.side)
                .background(background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .hint(help)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private var foreground: Color {
        guard isEnabled else { return Color.secondary.opacity(0.5) }
        if isOn {
            return .accentColor
        }
        return isHovered ? .primary : .secondary
    }

    private var background: Color {
        guard isEnabled else { return .clear }
        if isOn {
            return Color.accentColor.opacity(isHovered ? 0.24 : 0.15)
        }
        return Color.primary.opacity(isHovered ? 0.1 : 0)
    }
}

#Preview {
    HStack(spacing: 4) {
        ToggleIconButton(systemImage: "text.justify.leading", help: "Show the whole file", isOn: false) {}
        ToggleIconButton(systemImage: "text.justify.leading", help: "Show only the changed parts", isOn: true) {}
        ToggleIconButton(systemImage: "rectangle.split.2x1", help: "Side by side", isOn: false) {}
            .disabled(true)
    }
    .padding()
}
