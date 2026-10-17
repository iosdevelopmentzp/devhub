import SwiftUI
import DevHubDomain
import DevHubUI

struct StashRow: View {
    let model: StashRowModel
    let onApply: () -> Void
    let onPop: () -> Void
    let onDrop: () -> Void

    @State private var isConfirmingDrop = false

    var body: some View {
        RowContainer(verticalPadding: 7) { isHovered in
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "tray.full")
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.message)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                            .hintWhenTruncated(model.message)
                        HStack(spacing: 6) {
                            Text(model.reference)
                                .font(.caption2.monospaced())
                                .copyOnClick(model.reference, label: model.reference)
                            if let branch = model.branch {
                                Text(branch)
                                    .font(.caption2.monospaced())
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            if let dateText = model.dateText {
                                Text(dateText)
                                    .font(.caption2.weight(.medium))
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    HoverActions(isVisible: isHovered && isConfirmingDrop == false, count: 3, spacing: 2) {
                        IconButton(systemImage: "tray.and.arrow.up", help: "Apply: bring the changes back and keep the stash") {
                            onApply()
                        }
                        IconButton(systemImage: "arrow.uturn.up", help: "Pop: bring the changes back and drop the stash") {
                            onPop()
                        }
                        IconButton(systemImage: "trash", help: "Drop the stash", tint: .red) {
                            isConfirmingDrop = true
                        }
                    }
                    .disabled(model.areActionsEnabled == false)
                }
                if isConfirmingDrop {
                    InlineConfirmation(
                        model.dropMessage,
                        confirmTitle: "Drop",
                        confirmRole: .destructive,
                        onCancel: { isConfirmingDrop = false },
                        onConfirm: {
                            isConfirmingDrop = false
                            onDrop()
                        }
                    )
                }
            }
        }
        .contextMenu {
            Button("Apply", systemImage: "tray.and.arrow.up", action: onApply)
            Button("Pop", systemImage: "arrow.uturn.up", action: onPop)
            Divider()
            Button("Drop…", systemImage: "trash", role: .destructive) { isConfirmingDrop = true }
        }
    }
}

#Preview {
    StashRow(model: .preview, onApply: {}, onPop: {}, onDrop: {})
        .previewEnvironment()
}
