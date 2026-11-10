import SwiftUI
import DevHubUI

struct PullRequestFileRow: View {
    @Environment(\.diffScrollProxy) private var scrollProxy
    @Environment(DiffViewport.self) private var viewport: DiffViewport?
    @Environment(\.diffFontSize) private var fontSize

    let model: PullRequestFileRowModel
    let actions: PullRequestDetailActions
    let isWide: Bool

    private static let layoutSettleDelay: Duration = .milliseconds(100)

    var body: some View {
        Section {
            if let diff = model.diff {
                DiffViewportGate(id: model.id, key: DiffGateKey(model: model, layout: layout), estimatedHeight: DiffViewportPolicy.estimatedHeight(of: diff, fontSize: fontSize)) {
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
                }
                .padding(.leading, 18)
                .padding(.bottom, 8)
            }
        } header: {
            PullRequestFileHeader(model: model, actions: actions, isWide: isWide)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(DiffViewport.coordinateSpace)) } action: { viewport?.update(headerFrame: $0, of: model.id) }
                .onDisappear { viewport?.forgetHeader(model.id) }
                .task(id: focusTarget) { await scrollToFocus() }
        }
    }

    private var layout: DiffLayout {
        model.layout == .sideBySide && isWide ? .sideBySide : .unified
    }

    private var focusTarget: FocusTarget? {
        guard model.isFocused else { return nil }
        return model.highlightedLineID.map(FocusTarget.line) ?? .file
    }

    private func scrollToFocus() async {
        guard let focusTarget else { return }
        if case .line = focusTarget, viewport?.nearIDs.contains(model.id) == false {
            scrollProxy?.scrollTo(PullRequestFileRowModel.scrollID(model.id), anchor: .top)
        }
        try? await Task.sleep(for: Self.layoutSettleDelay)
        guard Task.isCancelled == false else { return }
        withAnimation(.snappy(duration: 0.25)) {
            switch focusTarget {
            case .file:
                scrollProxy?.scrollTo(PullRequestFileRowModel.scrollID(model.id), anchor: .top)
            case .line(let line):
                scrollProxy?.scrollTo(DiffLineModel.scrollID(scope: model.id, line: line), anchor: .center)
            }
        }
    }
}

private enum FocusTarget: Equatable {
    case file
    case line(Int)
}

private struct DiffGateKey: Equatable {
    let model: PullRequestFileRowModel
    let layout: DiffLayout
}

#Preview {
    VStack(spacing: 0) {
        PullRequestFileRow(model: .preview, actions: .preview, isWide: true)
    }
    .previewEnvironment()
    .padding()
    .frame(width: 640)
}
