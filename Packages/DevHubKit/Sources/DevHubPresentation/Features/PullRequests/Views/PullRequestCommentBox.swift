import SwiftUI
import DevHubUI

struct PullRequestCommentBox: View {
    let model: PullRequestCommentBoxModel
    let onChange: (String) -> Void
    let onSend: (PullRequestDetailStore.CommentKind) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField(model.placeholder, text: draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .font(.callout)
                .lineLimit(2...8)
                .disabled(model.isBusy)
            HStack(spacing: 8) {
                if model.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                if model.canRequestChanges {
                    Button("Request Changes", systemImage: "exclamationmark.bubble") {
                        onSend(.requestChanges)
                    }
                    .controlSize(.small)
                    .disabled(model.canSend == false)
                    .hint(model.requestChangesHint)
                }
                Button("Comment", systemImage: "text.bubble") {
                    onSend(.comment)
                }
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(model.canSend == false)
                .hint("Post the comment (⌘Return)")
            }
        }
    }

    private var draft: Binding<String> {
        Binding(get: { model.draft }, set: onChange)
    }
}

#Preview {
    PullRequestCommentBox(model: .preview, onChange: { _ in }, onSend: { _ in })
        .padding()
        .frame(width: 520)
}
