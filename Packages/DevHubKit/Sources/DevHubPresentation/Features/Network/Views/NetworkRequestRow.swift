import SwiftUI
import DevHubDomain
import DevHubUI

struct NetworkRequestRow: View {
    let model: NetworkRequestRowModel
    let onToggle: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 7, isHighlighted: model.isSelected) { isHovered in
            HStack(spacing: 10) {
                Tag(model.method, tint: model.methodTint.color)
                    .frame(width: 52, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.path)
                        .font(.callout.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(model.path)
                    HStack(spacing: 6) {
                        Text(model.host)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        ForEach(model.tags, id: \.self) { tag in
                            ModelTag(model: tag)
                        }
                    }
                }
                Spacer(minLength: 6)
                Tag(model.status, tint: model.statusTint.color)
                    .hint(model.statusHint)
                Text(model.duration)
                    .font(.caption.monospaced())
                    .foregroundStyle(model.durationTint.color)
                    .frame(minWidth: 52, alignment: .trailing)
                    .fixedSize()
                Text(model.time)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Image(systemName: model.isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .opacity(isHovered || model.isSelected ? 1 : 0)
            }
        }
        .onTapGesture(perform: onToggle)
    }
}

#Preview {
    NetworkRequestRow(model: .preview, onToggle: {})
        .previewEnvironment()
        .frame(width: 720)
}
