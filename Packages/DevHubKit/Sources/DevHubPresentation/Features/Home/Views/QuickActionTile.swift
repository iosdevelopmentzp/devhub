import SwiftUI
import DevHubDomain
import DevHubUI

struct QuickActionTile: View {
    let action: QuickAction
    let isRunning: Bool
    let perform: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: perform) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    IconTile(systemImage: action.systemImage, tint: action.tint.color, size: 28)
                    Spacer()
                    if isRunning {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(action.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.accentColor.opacity(0.06) : Theme.surface)
                    .shadow(color: Theme.shadow, radius: 3, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isHovered ? Color.accentColor.opacity(0.5) : Theme.border)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .disabled(isRunning)
    }
}

#Preview {
    QuickActionTile(action: QuickAction.all[0], isRunning: false) {}
        .frame(width: 160)
        .padding()
}
