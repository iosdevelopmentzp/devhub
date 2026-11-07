import SwiftUI
import DevHubUI

struct PullRequestFileSidebarRow: View {
    @Environment(Toaster.self) private var toaster

    let model: PullRequestFileSidebarRowModel
    let isSelected: Bool
    let actions: PullRequestDetailActions
    let onSelect: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 5, isHighlighted: isSelected) { _ in
            HStack(alignment: .top, spacing: 8) {
                Text(model.letter)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(model.isViewed ? Color.secondary : model.letterTint.color)
                    .frame(width: 14)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(model.fileName)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(model.isViewed ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        if model.isChanged {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .hint("Changed since your review")
                        }
                        if let threadCountText = model.threadCountText {
                            Label(threadCountText, systemImage: "bubble.left")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                                .fixedSize()
                                .hint("Open threads on this file")
                        }
                    }
                    HStack(spacing: 6) {
                        Text(model.folder)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                        Spacer(minLength: 2)
                        Text(model.additionsText)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.green)
                        Text(model.deletionsText)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.red)
                    }
                }
                Image(systemName: model.isViewed ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(model.isViewed ? Color.green : Color.secondary.opacity(0.5))
                    .padding(.top, 2)
                    .hint(model.isViewed ? "Viewed. Click to clear the mark." : "Not viewed yet. Click to mark the file as viewed.")
                    .onTapGesture { actions.toggleViewed(model.id) }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .hint(model.hint)
        .contextMenu {
            Button("Show Diff", systemImage: "text.alignleft", action: onSelect)
            Button(model.isViewed ? "Clear Viewed" : "Mark as Viewed", systemImage: "checkmark.circle") { actions.toggleViewed(model.id) }
            Divider()
            Button("Open in Editor", systemImage: "arrow.up.forward.app") { actions.openFile(model.path, nil) }
            Button("Open in Browser", systemImage: "safari") { actions.openFileOnWeb(model.path, nil) }
            Divider()
            Button("Copy Path", systemImage: "doc.on.doc") { toaster.copy(model.path) }
            Button("Copy File Name", systemImage: "doc.on.doc") { toaster.copy(model.fileName) }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        PullRequestFileSidebarRow(model: .preview, isSelected: true, actions: .preview, onSelect: {})
        PullRequestFileSidebarRow(model: PullRequestFileSidebarModel.preview.rows[1], isSelected: false, actions: .preview, onSelect: {})
    }
    .previewEnvironment()
    .frame(width: 280)
}
