import SwiftUI
import DevHubDomain
import DevHubUI

struct CopyHistoryRow: View {
    let model: CopyHistoryRowModel
    let onResend: () -> Void
    let onRemove: () -> Void

    var body: some View {
        RowContainer(verticalPadding: 7) { isHovered in
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.text)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .copyOnClick(model.text, label: model.text)
                    Text(model.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                HoverActions(isVisible: isHovered, count: 2, spacing: 2) {
                    IconButton(systemImage: "arrow.counterclockwise", help: model.resendHint, action: onResend)
                    IconButton(systemImage: "xmark", help: "Remove from Recent", action: onRemove)
                }
            }
        }
        .contextMenu {
            Button("Resend", systemImage: "arrow.counterclockwise", action: onResend)
            Button("Remove from Recent", systemImage: "xmark", action: onRemove)
        }
    }
}

#Preview {
    CopyHistoryRow(model: .preview, onResend: {}, onRemove: {})
        .previewEnvironment()
}
