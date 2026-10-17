import SwiftUI
import DevHubUI

struct MergeRequestFileRow: View {
    let model: MergeRequestFileRowModel
    let actions: MergeRequestDetailActions

    var body: some View {
        Section {
            if let diff = model.diff {
                DiffView(model: diff, scrollScope: model.id, highlightedLineID: model.highlightedLineID, onOpenLine: { actions.openFile(model.path, $0) }) { lineID in
                    ForEach(model.diffThreads[lineID] ?? []) { thread in
                        DiffThreadBubble(
                            model: thread,
                            onToggle: { actions.toggleDiffThread(thread.id) },
                            onOpenFile: { actions.openFile(model.path, thread.thread.line) },
                            onResolve: { actions.resolveThread(thread.id) },
                            onReply: { actions.reply(thread.id, $0) }
                        )
                    }
                }
                .padding(.leading, 18)
                    .padding(.bottom, 8)
            }
        } header: {
            header
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: model.isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 10)
            Text(model.letter)
                .font(.caption.monospaced().weight(.bold))
                .foregroundStyle(model.isViewed ? Color.secondary : model.letterTint.color)
                .frame(width: 16)
                .hint(model.letterHint)
            HStack(spacing: 6) {
                Text(model.fileName)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(model.isViewed ? .secondary : .primary)
                    .lineLimit(1)
                Text(model.detail)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .hintWhenTruncated(model.path)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { actions.toggleFile(model.id) }
            if let threadCountText = model.threadCountText {
                Label(threadCountText, systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize()
                    .hint("Open threads on this file")
            }
            Text(model.additionsText)
                .font(.caption.monospaced())
                .foregroundStyle(.green)
            Text(model.deletionsText)
                .font(.caption.monospaced())
                .foregroundStyle(.red)
            Toggle("Viewed", isOn: Binding(get: { model.isViewed }, set: { _ in actions.toggleViewed(model.id) }))
                .toggleStyle(.checkbox)
                .font(.caption)
                .fixedSize()
                .hint("Mark the file as viewed: it folds and its name turns grey. DevHub keeps the mark until it quits.")
            IconButton(systemImage: "arrow.up.forward.app", help: "Open in Xcode, from the branch's checkout or the main checkout. Double-click a diff line to open it at that line.") {
                actions.openFile(model.path, nil)
            }
        }
        .padding(.vertical, 4)
        .background(Theme.base)
    }
}

#Preview {
    LazyVStack(pinnedViews: [.sectionHeaders]) {
        MergeRequestFileRow(model: .preview, actions: .preview)
    }
    .previewEnvironment()
    .padding()
    .frame(width: 640)
}
