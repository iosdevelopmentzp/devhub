import SwiftUI
import DevHubUI

struct SplitDiffRow: View {
    let model: SplitDiffRowModel
    let highlightedLineID: Int?
    let onOpenLine: ((_ line: Int) -> Void)?
    let onOpenLineOnWeb: ((_ line: Int) -> Void)?
    let onCommentLine: ((DiffLineModel) -> Void)?

    var body: some View {
        if let header = model.header {
            DiffLine(model: header, isHighlighted: header.id == highlightedLineID, onOpen: nil, onOpenOnWeb: nil, onComment: nil)
        } else {
            HStack(alignment: .top, spacing: 0) {
                cell(model.old, side: .old)
                Divider()
                cell(model.new, side: .new)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func cell(_ line: DiffLineModel?, side: DiffSide) -> some View {
        if let line {
            DiffLine(
                model: line,
                side: side,
                isHighlighted: line.id == highlightedLineID,
                onOpen: openAction(for: line),
                onOpenOnWeb: webAction(for: line),
                onComment: commentAction(for: line)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Color.primary.opacity(0.03)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func openAction(for line: DiffLineModel) -> (() -> Void)? {
        guard let onOpenLine, let number = line.newNumber ?? line.oldNumber else { return nil }
        return { onOpenLine(number) }
    }

    private func webAction(for line: DiffLineModel) -> (() -> Void)? {
        guard let onOpenLineOnWeb, let number = line.newNumber else { return nil }
        return { onOpenLineOnWeb(number) }
    }

    private func commentAction(for line: DiffLineModel) -> (() -> Void)? {
        guard let onCommentLine, line.newNumber != nil || line.oldNumber != nil else { return nil }
        return { onCommentLine(line) }
    }
}

#Preview {
    VStack(spacing: 0) {
        SplitDiffRow(model: SplitDiffRowModel(id: 0, header: DiffLineModel(id: 0, text: "@@ -40,3 +40,4 @@", tint: .blue, foregroundOpacity: 1, backgroundOpacity: 0.06), old: nil, new: nil), highlightedLineID: nil, onOpenLine: nil, onOpenLineOnWeb: nil, onCommentLine: nil)
        SplitDiffRow(model: .preview, highlightedLineID: 1, onOpenLine: nil, onOpenLineOnWeb: nil, onCommentLine: { _ in })
    }
    .frame(width: 720)
}
