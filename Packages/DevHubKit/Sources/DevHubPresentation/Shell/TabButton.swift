import SwiftUI
import DevHubDomain
import DevHubUI

struct TabButton: View {
    let feature: Feature
    let isSelected: Bool
    let shortcutIndex: Int
    let showsTitle: Bool
    let badge: Int?
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: feature.systemImage)
                if showsTitle {
                    Text(feature.title)
                        .lineLimit(1)
                        .fixedSize()
                }
                if let badge {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white : Color.accentColor, in: Capsule())
                        .foregroundStyle(isSelected ? Color.accentColor : Color.white)
                        .fixedSize()
                }
            }
            .font(.callout.weight(isSelected ? .semibold : .regular))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(backgroundColor)
                    .animation(.snappy(duration: 0.15), value: isSelected)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(Character(String(shortcutIndex))), modifiers: .command)
        .onHover { isHovered = $0 }
        .hint("\(feature.title) (⌘\(shortcutIndex))")
    }

    private var backgroundColor: Color {
        if isSelected { return .accentColor }
        if isHovered { return Theme.hover }
        return .clear
    }
}
