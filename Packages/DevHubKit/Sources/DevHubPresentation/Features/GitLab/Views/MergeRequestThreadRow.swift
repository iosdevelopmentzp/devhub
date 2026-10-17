import SwiftUI
import DevHubUI

struct MergeRequestThreadRow: View {
    @Environment(AppActions.self) private var appActions

    let model: MergeRequestThreadRowModel
    let onShowInDiff: () -> Void
    let onOpenFile: () -> Void
    let onResolve: () -> Void
    let onReply: (_ body: String) -> Void

    @State private var showsReplies = false
    @State private var isReplying = false
    @State private var replyText = ""

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "bubble.left")
                .font(.caption)
                .foregroundStyle(.orange)
                .frame(width: 16)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.author)
                        .font(.caption.weight(.semibold))
                    if let location = model.location {
                        Text(location)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .copyOnClick(model.locationHint ?? location, label: location)
                    }
                    if let replies = model.repliesText {
                        Button(showsReplies ? "Hide replies" : replies) {
                            showsReplies.toggle()
                        }
                        .buttonStyle(.link)
                        .font(.caption2)
                    }
                }
                Text(model.body)
                    .font(.caption)
                    .lineLimit(showsReplies ? nil : 3)
                    .hintWhenTruncated(model.body)
                if isReplying {
                    HStack(alignment: .top, spacing: 6) {
                        TextField("Reply…", text: $replyText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                            .lineLimit(1...6)
                        Button("Send") {
                            onReply(replyText)
                            replyText = ""
                            isReplying = false
                        }
                        .controlSize(.small)
                        .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button("Cancel") {
                            replyText = ""
                            isReplying = false
                        }
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
                if showsReplies {
                    ForEach(model.replies) { reply in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(reply.author)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(reply.body)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                        .padding(.leading, 10)
                        .padding(.top, 4)
                    }
                }
            }
            Spacer(minLength: 0)
            if model.isBusy {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 24, height: 24)
            } else {
                threadActions
            }
        }
    }

    private var threadActions: some View {
        HStack(spacing: 2) {
                if model.canShowInDiff {
                    IconButton(systemImage: "arrow.down.forward.circle", help: "Show the commented line in the diff below") {
                        onShowInDiff()
                    }
                }
                if model.filePath != nil {
                    IconButton(systemImage: "arrow.up.forward.app", help: "Open the file in Xcode at this line, from the branch's checkout or the main checkout") {
                        onOpenFile()
                    }
                }
                if model.noteURL != nil {
                    IconButton(systemImage: "globe", help: "Open this thread in GitLab") {
                        appActions.open(model.noteURL)
                    }
                }
                IconButton(systemImage: "arrowshape.turn.up.left", help: "Reply in this thread") {
                    isReplying.toggle()
                }
                IconButton(systemImage: "checkmark.circle", help: "Resolve this thread", tint: .green) {
                    onResolve()
                }
        }
        .fixedSize()
    }
}

#Preview {
    MergeRequestThreadRow(model: .preview, onShowInDiff: {}, onOpenFile: {}, onResolve: {}, onReply: { _ in })
        .previewEnvironment()
        .padding()
}
