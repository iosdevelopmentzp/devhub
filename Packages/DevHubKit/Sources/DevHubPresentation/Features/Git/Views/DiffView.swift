import SwiftUI
import DevHubDomain
import DevHubUI

struct DiffView<Accessory: View>: View {
    @Environment(\.diffScrollProxy) private var scrollProxy

    let model: DiffModel
    let scrollScope: String?
    let highlightedLineID: Int?
    let onOpenLine: ((_ line: Int) -> Void)?
    let onCommentLine: ((DiffLineModel) -> Void)?
    let accessory: (_ lineID: Int) -> Accessory

    init(
        model: DiffModel,
        scrollScope: String?,
        highlightedLineID: Int?,
        onOpenLine: ((_ line: Int) -> Void)?,
        onCommentLine: ((DiffLineModel) -> Void)?,
        @ViewBuilder accessory: @escaping (_ lineID: Int) -> Accessory
    ) {
        self.model = model
        self.scrollScope = scrollScope
        self.highlightedLineID = highlightedLineID
        self.onOpenLine = onOpenLine
        self.onCommentLine = onCommentLine
        self.accessory = accessory
    }

    var body: some View {
        Group {
            switch model {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            case .note(let text):
                note(text)
            case .lines(let lines, let droppedNote):
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(lines) { line in
                        DiffLine(model: line, isHighlighted: line.id == highlightedLineID, onOpen: openAction(for: line), onComment: commentAction(for: line))
                            .id(scrollID(line.id))
                        accessory(line.id)
                    }
                    if let droppedNote {
                        note(droppedNote)
                    }
                }
                .padding(.vertical, 4)
                .task(id: highlightedLineID) {
                    guard let highlightedLineID else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        scrollProxy?.scrollTo(scrollID(highlightedLineID), anchor: .center)
                    }
                }
            }
        }
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Theme.border))
    }

    private func scrollID(_ line: Int) -> String {
        "diff-line:\(scrollScope ?? "")#\(line)"
    }

    private func openAction(for line: DiffLineModel) -> (() -> Void)? {
        guard let onOpenLine, let number = line.newNumber ?? line.oldNumber else { return nil }
        return { onOpenLine(number) }
    }

    private func commentAction(for line: DiffLineModel) -> (() -> Void)? {
        guard let onCommentLine, line.newNumber != nil || line.oldNumber != nil else { return nil }
        return { onCommentLine(line) }
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
    }
}

extension DiffView where Accessory == EmptyView {
    init(model: DiffModel, scrollScope: String?, highlightedLineID: Int?, onOpenLine: ((_ line: Int) -> Void)?) {
        self.init(model: model, scrollScope: scrollScope, highlightedLineID: highlightedLineID, onOpenLine: onOpenLine, onCommentLine: nil) { _ in
            EmptyView()
        }
    }
}

#Preview {
    DiffView(model: .preview, scrollScope: "preview", highlightedLineID: 1, onOpenLine: nil)
        .padding()
}
