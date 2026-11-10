import SwiftUI
import DevHubUI

struct DiffFindBar: View {
    let model: DiffFindModel
    let focus: FocusState<Bool>.Binding
    let onChange: (String) -> Void
    let onStep: (_ offset: Int) -> Void
    let onClose: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            SearchField(prompt: "Find in diffs", text: Binding(get: { model.query }, set: onChange), focus: focus, onExit: onClose)
                .frame(maxWidth: 320)
                .onSubmit { onStep(1) }
                .hint("Find text in the diffs of every listed file, open or folded. Return or ⌘G goes to the next match and opens its file, ⇧⌘G to the previous one. Esc \(onClose == nil ? "clears the field" : "closes the bar").")
            if let countText = model.countText {
                Text(countText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            IconButton(systemImage: "chevron.up", help: "Previous match (⇧⌘G)") {
                onStep(-1)
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            .disabled(model.canStep == false)
            IconButton(systemImage: "chevron.down", help: "Next match (⌘G)") {
                onStep(1)
            }
            .keyboardShortcut("g", modifiers: .command)
            .disabled(model.canStep == false)
            Spacer(minLength: 4)
            if let onClose {
                IconButton(systemImage: "xmark", help: "Close the find bar (Esc)", action: onClose)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Theme.base)
    }
}

#Preview {
    @Previewable @FocusState var isFocused: Bool
    VStack(spacing: 0) {
        DiffFindBar(model: .preview, focus: $isFocused, onChange: { _ in }, onStep: { _ in }, onClose: {})
        Divider()
        DiffFindBar(model: .preview, focus: $isFocused, onChange: { _ in }, onStep: { _ in }, onClose: nil)
    }
    .frame(width: 640)
}
