import SwiftUI
import DevHubUI

struct MergeRequestCompactRow: View {
    @Environment(Toaster.self) private var toaster
    @Environment(AppActions.self) private var appActions

    let model: MergeRequestCompactRowModel
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 6, isHighlighted: isSelected) { _ in
            HStack(spacing: 8) {
                Image(systemName: model.icon)
                    .foregroundStyle(model.iconTint.color)
                    .frame(width: 16)
                    .hint(model.iconHint)
                if model.isNew {
                    StatusDot(color: Tint.blue.color)
                        .hint("Updated since your last visit")
                }
                Text(model.reference)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .copyOnClick(model.reference, label: model.reference)
                Text(model.title)
                    .font(.callout)
                    .lineLimit(1)
                    .hintWhenTruncated(model.title)
                Spacer(minLength: 8)
                HStack(spacing: 8) {
                    ForEach(model.signals, id: \.self) { signal in
                        ModelTag(model: signal, isPlain: true)
                    }
                }
                if model.author.isEmpty == false {
                    Text(model.author)
                        .font(.caption)
                        .foregroundStyle(model.authorTint?.color ?? .secondary)
                        .lineLimit(1)
                        .fixedSize()
                }
                if let dateText = model.dateText {
                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
        }
        .contextMenu {
            Button("Open in GitLab", systemImage: "globe") { appActions.open(model.webURL) }
            Button("Copy Link", systemImage: "link") {
                guard let url = model.webURL else { return }
                toaster.copy(url.absoluteString, label: model.reference)
            }
            Button("Copy Link with Title", systemImage: "text.bubble") { toaster.copy(model.linkText, label: "Link with title") }
        }
    }
}

#Preview {
    MergeRequestCompactRow(model: .preview, isSelected: false, onToggle: {})
        .previewEnvironment()
}
