import SwiftUI
import DevHubDomain
import DevHubUI

struct DiskCleanupRow: View {
    let model: DiskCleanupRowModel
    let isConfirming: Bool
    let onRequestDelete: () -> Void
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: model.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(model.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(model.detail)
                }
                Spacer(minLength: 8)
                size
                Button("Delete…", role: .destructive, action: onRequestDelete)
                    .controlSize(.small)
                    .fixedSize()
                    .disabled(model.canDelete == false || isConfirming)
                    .hint(model.deleteHint)
            }
            if isConfirming {
                InlineConfirmation(
                    model.confirmTitle,
                    confirmTitle: "Delete",
                    confirmRole: .destructive,
                    layout: .stacked(warnings: model.warnings),
                    onCancel: onCancel,
                    onConfirm: onConfirm
                )
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var size: some View {
        if model.isBusy || model.isMeasuring {
            ProgressView()
                .controlSize(.small)
        } else if let sizeText = model.sizeText {
            Text(sizeText)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize()
        }
    }
}

#Preview {
    DiskCleanupRow(model: .preview, isConfirming: true, onRequestDelete: {}, onCancel: {}, onConfirm: {})
        .padding()
        .previewEnvironment()
}
