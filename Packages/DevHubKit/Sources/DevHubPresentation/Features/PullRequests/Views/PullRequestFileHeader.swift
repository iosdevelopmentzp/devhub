import SwiftUI
import DevHubUI

struct PullRequestFileHeader: View {
    @Environment(\.copyToPasteboard) private var copyToPasteboard
    @Environment(\.codeHostWords) private var words

    let model: PullRequestFileRowModel
    let actions: PullRequestDetailActions
    let isWide: Bool

    var body: some View {
        HoverHitTestGate {
            content
        }
        .padding(.vertical, 4)
        .background(Theme.base)
        .contextMenu { contextMenu }
    }

    private var content: some View {
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
                if model.isFullLoading {
                    ProgressView()
                        .controlSize(.mini)
                        .frame(width: IconButton.side, height: IconButton.side)
                        .hint("Reading the whole file…")
                } else {
                    ToggleIconButton(systemImage: "text.justify.leading", help: fullHint, isOn: model.isFull) {
                        actions.toggleFullFile(model.id)
                    }
                }
            }
            if let layoutHint = model.layoutHint {
                ToggleIconButton(systemImage: DiffLayout.sideBySide.icon, help: isWide ? layoutHint : narrowHint, isOn: layout == .sideBySide) {
                    actions.toggleFileLayout(model.id)
                }
                .disabled(isWide == false)
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
    }

    private var narrowHint: String {
        "Side by side needs \(Int(PullRequestDetailsView.sideBySideMinimumWidth)) points of width. Open the \(words.request) in its window or widen the panel."
    }

    private var layout: DiffLayout {
        model.layout == .sideBySide && isWide ? .sideBySide : .unified
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(model.isExpanded ? "Fold Diff" : "Open Diff", systemImage: model.isExpanded ? "chevron.down" : "chevron.right") {
            actions.toggleFile(model.id)
        }
        Button(model.isViewed ? "Mark as Not Viewed" : "Mark as Viewed", systemImage: model.isViewed ? "square" : "checkmark.square") {
            actions.toggleViewed(model.id)
        }
        if model.fullHint != nil {
            Button(model.isFull ? "Show Only Changed Parts" : "Show Whole File", systemImage: "text.justify.leading") {
                actions.toggleFullFile(model.id)
            }
        }
        if model.layoutHint != nil {
            Button(layout == .sideBySide ? "Show Unified" : "Show Side by Side", systemImage: DiffLayout.sideBySide.icon) {
                actions.toggleFileLayout(model.id)
            }
            .disabled(isWide == false)
        }
        Divider()
        Button("Open in Editor", systemImage: "arrow.up.forward.app") {
            actions.openFile(model.path, nil)
        }
        if model.canOpenOnWeb {
            Button("Open in Browser", systemImage: "safari") {
                actions.openFileOnWeb(model.path, nil)
            }
        }
        Button("Copy Path", systemImage: "doc.on.doc") {
            copyToPasteboard(model.path, "path")
        }
        if model.canUnhide {
            Divider()
            Button("Show This File Again", systemImage: "eye") {
                actions.unhideFile(model.path)
            }
        } else if model.canHide {
            Divider()
            Button("Hide This File", systemImage: "eye.slash") {
                actions.hideFiles([model.path])
            }
        }
    }
}

#Preview {
    PullRequestFileHeader(model: .preview, actions: .preview, isWide: true)
        .previewEnvironment()
        .padding()
        .frame(width: 640)
}
