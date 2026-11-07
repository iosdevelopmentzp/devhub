import SwiftUI
import DevHubUI

struct PullRequestFileRow: View {
    @Environment(\.diffScrollProxy) private var scrollProxy

    let model: PullRequestFileRowModel
    let actions: PullRequestDetailActions
    var layout = DiffLayout.unified

    private static let layoutSettleDelay: Duration = .milliseconds(100)

    var body: some View {
        Section {
            if let diff = model.diff {
                DiffView(
                    model: diff,
                    layout: layout,
                    scrollScope: model.id,
                    highlightedLineID: model.highlightedLineID,
                    onOpenLine: { actions.openFile(model.path, $0) },
                    onOpenLineOnWeb: { actions.openFileOnWeb(model.path, $0) },
                    onCommentLine: { actions.startLineComment(model.path, model.oldPath, $0) }
                ) { lineID in
                    if let composer = model.lineComposer, composer.lineID == lineID {
                        LineCommentComposer(
                            model: composer,
                            onChange: actions.setLineCommentText,
                            onSend: actions.sendLineComment,
                            onCancel: actions.cancelLineComment
                        )
                    }
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
                    .layoutPriority(1)
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
            if let reviewTag = model.reviewTag {
                ModelTag(model: reviewTag)
            }
            if let hiddenTag = model.hiddenTag {
                ModelTag(model: hiddenTag)
            }
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
            if let fullHint = model.fullHint {
                IconButton(systemImage: "text.justify.leading", help: fullHint, tint: model.isFull ? .accentColor : .primary) {
                    actions.toggleFullFile(model.id)
                }
            }
            if model.canOpenOnWeb {
                IconButton(systemImage: "safari", help: "Open the whole file in the browser at the last commit. Right-click a diff line to open it at that line.") {
                    actions.openFileOnWeb(model.path, nil)
                }
            }
            if model.canUnhide {
                IconButton(systemImage: "eye", help: "Show this file again in the requests of this project") {
                    actions.unhideFile(model.path)
                }
            } else if model.canHide {
                IconButton(systemImage: "eye.slash", help: "Hide this file in the requests of this project. \"Show N hidden\" lists it again.") {
                    actions.hideFiles([model.path])
                }
            }
            IconButton(systemImage: "arrow.up.forward.app", help: "Open in the editor chosen in Settings, from the branch's checkout or the main checkout. Double-click a diff line to open it at that line.") {
                actions.openFile(model.path, nil)
            }
        }
        .padding(.vertical, 4)
        .background(Theme.base)
        .task(id: model.isFocused) {
            guard model.isFocused else { return }
            try? await Task.sleep(for: Self.layoutSettleDelay)
            withAnimation(.snappy(duration: 0.25)) {
                scrollProxy?.scrollTo(PullRequestFileRowModel.scrollID(model.id), anchor: .top)
            }
        }
    }
}

#Preview {
    LazyVStack(pinnedViews: [.sectionHeaders]) {
        PullRequestFileRow(model: .preview, actions: .preview)
    }
    .previewEnvironment()
    .padding()
    .frame(width: 640)
}
