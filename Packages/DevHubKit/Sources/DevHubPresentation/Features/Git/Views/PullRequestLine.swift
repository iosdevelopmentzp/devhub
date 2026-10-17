import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestLine: View {
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster
    @Environment(\.codeHostWords) private var words

    let model: PullRequestLineModel
    let terminalPath: String
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.pull")
                .foregroundStyle(.secondary)
                .hint("\(words.requestSentence) and \(words.checks) of this branch on \(words.name), read with \(words.tool)")
            content
            Spacer(minLength: 0)
            if model.isLoading {
                ProgressView()
                    .controlSize(.mini)
            } else if model.canRefresh {
                IconButton(systemImage: "arrow.clockwise", help: "Ask \(words.name) again") {
                    onRefresh()
                }
            }
        }
        .font(.caption)
    }

    @ViewBuilder
    private var content: some View {
        switch model.content {
        case .notConnected(let command):
            Text("\(words.hostTitle) is not connected.")
                .foregroundStyle(.orange)
            Text(command)
                .font(.caption.monospaced())
                .copyOnClick(command, label: command)
            Button("Terminal") {
                appActions.openTerminal(at: terminalPath)
            }
            .controlSize(.mini)
            .fixedSize()
            .hint("Open a terminal, paste the command, follow the steps. DevHub never sees the token: \(words.tool) keeps it.")
        case .failure(let message):
            Text(message)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .hintWhenTruncated(message)
        case .status(let status):
            statusTags(status)
        case .checking:
            Text("Checking \(words.name)…")
                .foregroundStyle(.secondary)
        }
    }

    private func statusTags(_ status: PullRequestLineModel.Status) -> some View {
        FlowLayout(spacing: 6, lineSpacing: 4) {
            if let tag = status.requestTag {
                ModelTag(model: tag)
                    .onTapGesture {
                        guard let iid = status.requestIID else { return }
                        appActions.showPullRequest(iid: iid)
                    }
            }
            if status.requestURL != nil {
                IconButton(systemImage: "globe", help: "Open the \(words.request) in \(words.name)") {
                    appActions.open(status.requestURL)
                }
            }
            if let linkText = status.linkText {
                IconButton(systemImage: "text.bubble", help: "Copy Link with Title: the reference, the title and the link") {
                    toaster.copy(linkText, label: "Link with title")
                }
            }
            ForEach(status.requestTags, id: \.self) { tag in
                ModelTag(model: tag)
            }
            if let placeholder = status.placeholder {
                Text(placeholder)
                    .foregroundStyle(.secondary)
            }
            if let tag = status.pipelineTag {
                ModelTag(model: tag)
                    .onTapGesture { appActions.open(status.pipelineURL) }
            }
        }
    }
}

#Preview {
    PullRequestLine(model: .preview, terminalPath: "/tmp", onRefresh: {})
        .padding()
        .previewEnvironment()
}
