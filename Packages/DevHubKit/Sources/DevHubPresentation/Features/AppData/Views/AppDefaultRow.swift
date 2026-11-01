import SwiftUI
import DevHubDomain
import DevHubUI

struct AppDefaultRow: View {
    @Environment(Toaster.self) private var toaster

    let model: AppDefaultRowModel
    let isDisabled: Bool
    let onSave: (AppDefaultValue) -> Void
    let onDelete: () -> Void

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var draft = ""

    var body: some View {
        RowContainer(verticalPadding: 4) { isHovered in
            VStack(alignment: .leading, spacing: 6) {
                if isEditing {
                    editor
                } else {
                    line(isHovered: isHovered)
                }
                if isConfirmingDelete {
                    InlineConfirmation(
                        "Delete \(model.key)?",
                        confirmTitle: "Delete",
                        confirmRole: .destructive,
                        onCancel: { isConfirmingDelete = false },
                        onConfirm: {
                            isConfirmingDelete = false
                            onDelete()
                        }
                    )
                }
            }
        }
        .contextMenu {
            Button("Copy Key", systemImage: "doc.on.doc") { toaster.copy(model.key, label: "Key") }
            Button("Copy Value", systemImage: "doc.on.doc") { toaster.copy(model.editText, label: "Value") }
        }
    }

    private func line(isHovered: Bool) -> some View {
        HStack(spacing: 8) {
            Text(model.key)
                .font(.caption.monospaced().weight(.medium))
                .lineLimit(1)
                .truncationMode(.middle)
                .hintWhenTruncated(model.key)
                .frame(minWidth: 120, maxWidth: 220, alignment: .leading)
            ModelTag(model: model.kindTag)
            Text(model.valueText)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .hintWhenTruncated(model.valueText)
                .frame(maxWidth: .infinity, alignment: .leading)
            HoverActions(isVisible: isHovered && isConfirmingDelete == false, count: 3, spacing: 2) {
                if let toggleValue = model.toggleValue, let toggleHint = model.toggleHint {
                    IconButton(systemImage: "switch.2", help: toggleHint, tint: .blue) { onSave(toggleValue) }
                }
                if model.canEdit {
                    IconButton(systemImage: "pencil", help: "Edit the value") { startEditing() }
                } else if let readOnlyHint = model.readOnlyHint {
                    Image(systemName: "lock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: IconButton.side, height: IconButton.side)
                        .hint(readOnlyHint)
                }
                IconButton(systemImage: "trash", help: "Delete this key", tint: .red) { isConfirmingDelete = true }
            }
            .disabled(isDisabled)
        }
    }

    private var editor: some View {
        HStack(spacing: 8) {
            Text(model.key)
                .font(.caption.monospaced().weight(.medium))
                .lineLimit(1)
            ModelTag(model: model.kindTag)
            TextField("Value", text: $draft)
                .textFieldStyle(.roundedBorder)
                .font(.caption.monospaced())
                .onSubmit(save)
            Button("Save", action: save)
                .disabled(AppDefaultsPolicy.value(kind: model.kind, text: draft) == nil || isDisabled)
                .fixedSize()
            Button("Cancel") { isEditing = false }
                .fixedSize()
        }
        .controlSize(.small)
    }

    private func startEditing() {
        draft = model.editText
        isEditing = true
    }

    private func save() {
        guard let value = AppDefaultsPolicy.value(kind: model.kind, text: draft) else { return }
        isEditing = false
        onSave(value)
    }
}

#Preview {
    AppDefaultRow(model: .preview, isDisabled: false, onSave: { _ in }, onDelete: {})
        .previewEnvironment()
        .frame(width: 640)
}
