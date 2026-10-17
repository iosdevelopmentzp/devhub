import SwiftUI

struct QuickActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Tint
    let isRunning: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                IconTile(systemImage: systemImage, tint: tint, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if isRunning {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .padding(10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? Color.accentColor.opacity(0.5) : Theme.border, lineWidth: 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .hintWhenTruncated(subtitle.isEmpty ? title : "\(title): \(subtitle)")
    }
}

#Preview {
    QuickActionTile(title: "Open folder", subtitle: "Show in Finder", systemImage: "folder", tint: .blue, isRunning: false) {}
        .padding()
        .previewEnvironment()
}
