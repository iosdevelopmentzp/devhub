import SwiftUI
import DevHubDomain
import DevHubUI

struct LogLineRow: View {
    let model: LogLineRowModel

    var body: some View {
        RowContainer(verticalPadding: 2) { isHovered in
            row(isHovered: isHovered)
        }
    }

    private func row(isHovered: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(model.timestamp)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(.secondary)
                .fixedSize()
            Circle()
                .fill(model.levelTint.color.opacity(model.levelOpacity))
                .frame(width: 6, height: 6)
                .hint(model.levelTitle)
            if let category = model.category {
                Text(category)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 140, alignment: .leading)
                    .hintWhenTruncated(category)
            }
            Text(model.message)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(model.messageTint?.color ?? Color.primary.opacity(0.85))
                .lineLimit(isHovered ? nil : 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .copyOnClick(model.message, label: "log line")
        }
    }
}

#Preview {
    LogLineRow(model: .preview)
        .previewEnvironment()
}
