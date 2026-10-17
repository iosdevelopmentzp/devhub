import SwiftUI
import DevHubUI

struct ReflogRow: View {
    @Environment(Toaster.self) private var toaster

    let model: ReflogRowModel
    let onToggle: () -> Void
    let onToggleFile: (_ path: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RowContainer(verticalPadding: 6) { _ in
                summary
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onToggle)
            }
            .contextMenu { menu }
            if let files = model.files {
                CommitFilesList(files: files, onToggleFile: onToggleFile)
                    .padding(.leading, 18)
                    .padding(.bottom, 6)
            }
        }
    }

    private var summary: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 10)
            Text(model.selector)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize()
                .copyOnClick(model.selector, label: model.selector)
            Text(model.shortHash)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .fixedSize()
                .copyOnClick(model.hash, label: model.shortHash)
            ModelTag(model: model.actionTag)
                .fixedSize()
            Text(model.message)
                .font(.callout)
                .lineLimit(1)
                .hintWhenTruncated(model.message)
            Spacer(minLength: 6)
            if let dateText = model.dateText {
                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var menu: some View {
        Button(model.isExpanded ? "Hide Files" : "Show Files", systemImage: "doc.text", action: onToggle)
        Divider()
        Button("Copy Hash", systemImage: "number") { toaster.copy(model.hash, label: model.shortHash) }
        Button("Copy Selector", systemImage: "doc.on.doc") { toaster.copy(model.selector) }
    }
}

#Preview {
    ReflogRow(model: .preview, onToggle: {}, onToggleFile: { _ in })
        .previewEnvironment()
}
