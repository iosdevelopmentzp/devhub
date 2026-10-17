import SwiftUI
import DevHubUI

struct DiffThreadBubble: View {
    let model: DiffThreadModel
    let onToggle: () -> Void
    let onOpenFile: () -> Void
    let onResolve: () -> Void
    let onReply: (_ body: String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: model.isOpen ? "chevron.down" : "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 10)
                Image(systemName: "bubble.left.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(model.author)
                    .font(.caption.weight(.semibold))
                if model.isOpen == false {
                    Text(model.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let replies = model.repliesText {
                        Text("· \(replies)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggle)
            .hint(model.isOpen ? "Fold this thread" : "Open this thread to read it, reply or resolve")
            if model.isOpen {
                ReviewThreadRow(model: model.thread, onShowInDiff: {}, onOpenFile: onOpenFile, onResolve: onResolve, onReply: onReply)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.orange.opacity(0.7))
                .frame(width: 2)
        }
        .padding(.leading, 76)
        .padding(.trailing, 8)
        .padding(.vertical, 3)
    }
}

#Preview {
    VStack {
        DiffThreadBubble(model: .preview, onToggle: {}, onOpenFile: {}, onResolve: {}, onReply: { _ in })
        DiffThreadBubble(model: { var open = DiffThreadModel.preview; open.isOpen = true; return open }(), onToggle: {}, onOpenFile: {}, onResolve: {}, onReply: { _ in })
    }
    .previewEnvironment()
    .frame(width: 640)
}
