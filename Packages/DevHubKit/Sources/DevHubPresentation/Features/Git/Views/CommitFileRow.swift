import SwiftUI
import DevHubUI

struct CommitFileRow: View {
    @Environment(Toaster.self) private var toaster

    let model: CommitFileRowModel
    let onToggleDiff: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 4) { _ in
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 10)
                    Text(model.letter)
                        .font(.caption.monospaced().weight(.bold))
                        .foregroundStyle(model.letterTint.color)
                        .frame(width: 16)
                        .hint(model.letterHint)
                    Text(model.fileName)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(model.detail)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                        .hintWhenTruncated(model.path)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleDiff)
                if let diff = model.diff {
                    DiffView(model: diff, scrollScope: nil, highlightedLineID: nil, onOpenLine: nil)
                        .padding(.leading, 18)
                }
            }
        }
        .contextMenu {
            Button(model.isExpanded ? "Hide Diff" : "Show Diff", systemImage: "text.alignleft", action: onToggleDiff)
            Button("Copy Path", systemImage: "doc.on.doc") { toaster.copy(model.path) }
            Button("Copy File Name", systemImage: "doc.on.doc") { toaster.copy(model.fileName) }
        }
    }
}

#Preview {
    CommitFileRow(model: .preview, onToggleDiff: {})
        .previewEnvironment()
}
