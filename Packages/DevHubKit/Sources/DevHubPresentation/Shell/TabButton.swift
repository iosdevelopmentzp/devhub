import SwiftUI
import DevHubDomain
import DevHubUI

struct TabButton: View {
    let item: TabItem
    let isSelected: Bool
    let shortcutIndex: Int?
    let showsTitle: Bool
    let badge: Int?
    let hintDetail: String?
    let action: () -> Void
    var stretches = true

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: item.systemImage)
                if showsTitle {
                    Text(item.title)
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
            .frame(maxWidth: stretches ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(backgroundColor)
                    .animation(.snappy(duration: 0.15), value: isSelected)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(shortcut)
        .onHover { isHovered = $0 }
        .hint(hint)
    }

    private var shortcutIndexWithinKeys: Int? {
        guard let shortcutIndex, shortcutIndex <= 9 else { return nil }
        return shortcutIndex
    }

    private var hint: String {
        let title = shortcutIndexWithinKeys.map { "\(item.title) (⌘\($0))" } ?? item.title
        guard let hintDetail else { return title }
        return "\(title). \(hintDetail)"
    }

    private var shortcut: KeyboardShortcut? {
        guard let index = shortcutIndexWithinKeys else { return nil }
        return KeyboardShortcut(KeyEquivalent(Character(String(index))), modifiers: .command)
    }

    private var backgroundColor: Color {
        if isSelected { return .accentColor }
        if isHovered { return Theme.hover }
        return .clear
    }
}
