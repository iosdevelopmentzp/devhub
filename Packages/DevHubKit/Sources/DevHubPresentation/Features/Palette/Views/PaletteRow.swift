import SwiftUI
import DevHubDomain
import DevHubUI

struct PaletteRow: View {
    let item: PaletteItem
    let isHighlighted: Bool
    let onRun: () -> Void

    var body: some View {
        Button(action: onRun) {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .frame(width: 20)
                    .foregroundStyle(isHighlighted ? Color.white : Color.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.callout)
                        .lineLimit(1)
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(isHighlighted ? Color.white.opacity(0.8) : Color.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(item.section)
                    .font(.caption2)
                    .foregroundStyle(isHighlighted ? Color.white.opacity(0.8) : Color.secondary)
                    .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundStyle(isHighlighted ? Color.white : Color.primary)
            .background(isHighlighted ? Color.accentColor : Color.clear, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaletteRow(item: PaletteItem(id: "tab:git", title: "Git", subtitle: "Show the tab", systemImage: "arrow.triangle.pull", section: "Tabs", command: .showTab(.feature(.git))), isHighlighted: true, onRun: {})
        .frame(width: 520)
        .padding()
}
