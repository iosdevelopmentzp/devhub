import SwiftUI
import DevHubDomain
import DevHubUI

struct MockRuleRow: View {
    let model: MockRuleRowModel
    let onToggleEnabled: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isConfirmingDelete = false

    var body: some View {
        RowContainer(verticalPadding: 7, isHighlighted: model.isEditing) { isHovered in
            if isConfirmingDelete {
                InlineConfirmation(
                    "Delete the rule \(model.method) \(model.path)?",
                    confirmTitle: "Delete",
                    confirmRole: .destructive,
                    onCancel: { isConfirmingDelete = false },
                    onConfirm: {
                        isConfirmingDelete = false
                        onDelete()
                    }
                )
            } else {
                content(isHovered: isHovered)
            }
        }
    }

    private func content(isHovered: Bool) -> some View {
        HStack(spacing: 10) {
            Toggle("Enabled", isOn: Binding(get: { model.isEnabled }, set: { _ in onToggleEnabled() }))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
                .hint(model.isEnabled ? "Turn this rule off" : "Turn this rule on")
            Tag(model.method, tint: model.methodTint.color)
                .frame(width: 52, alignment: .leading)
            Text(model.path)
                .font(.callout.monospaced())
                .foregroundStyle(model.isEnabled ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .hintWhenTruncated(model.path)
            Spacer(minLength: 6)
            Text(model.summary)
                .font(.caption)
                .foregroundStyle(model.summaryTint.color)
                .fixedSize()
            HStack(spacing: 2) {
                IconButton(systemImage: model.isEditing ? "chevron.up" : "pencil", help: model.isEditing ? "Close the editor" : "Edit this rule", action: onEdit)
                IconButton(systemImage: "trash", help: "Delete this rule", tint: .red) {
                    isConfirmingDelete = true
                }
            }
            .opacity(isHovered || model.isEditing ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

#Preview {
    MockRuleRow(model: .preview, onToggleEnabled: {}, onEdit: {}, onDelete: {})
        .previewEnvironment()
        .frame(width: 720)
}
