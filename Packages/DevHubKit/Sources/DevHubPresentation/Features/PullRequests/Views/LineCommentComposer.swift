import SwiftUI
import DevHubUI

struct LineCommentComposer: View {
    let model: LineComposerModel
    let onChange: (String) -> Void
    let onSend: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField(model.placeholder, text: Binding(get: { model.text }, set: onChange), axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .lineLimit(2...8)
                .disabled(model.isBusy)
            HStack(spacing: 8) {
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Cancel", action: onCancel)
                    .controlSize(.small)
                    .keyboardShortcut(.cancelAction)
                    .disabled(model.isBusy)
                Button("Comment", systemImage: "plus.bubble", action: onSend)
                    .controlSize(.small)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(model.canSend == false)
                    .hint("Start a review thread on this line (⌘Return)")
            }
        }
        .padding(8)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(Color.accentColor.opacity(0.5)))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

#Preview {
    LineCommentComposer(model: .preview, onChange: { _ in }, onSend: {}, onCancel: {})
        .padding()
        .frame(width: 520)
}
