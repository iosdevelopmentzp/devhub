import SwiftUI

struct GitPullRequestLine: View {
    @Environment(GitStore.self) private var store
    @Environment(Toaster.self) private var toaster

    var body: some View {
        if let load = store.pullRequest {
            HStack(spacing: 6) {
                content(load)
                Spacer(minLength: 4)
                IconButton(systemImage: "arrow.clockwise", help: "Reload the pull request status") {
                    Task { await store.loadPullRequest(force: true) }
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ load: PullRequestLoad) -> some View {
        switch load {
        case let .found(info):
            FlowLayout(spacing: 6, lineSpacing: 4) {
                Tag("\(info.label) \(info.state.rawValue)", tint: stateTint(info.state), systemImage: info.isMergeRequest ? "arrow.triangle.merge" : "arrow.triangle.pull")
                if info.hasConflicts {
                    Tag("conflicts", tint: .red)
                }
                if let review = info.review {
                    Tag(review, tint: .gray)
                }
                checks(info)
            }
            .contentShape(Rectangle())
            .onTapGesture { store.openPullRequest() }
            .hint("Open \(info.label) on the web")
        case .none:
            Text("No pull request for this branch")
                .font(.caption)
                .foregroundStyle(.secondary)
        case let .notInstalled(command):
            commandHint("Install the command line tool to see the pull request:", command: command)
        case let .notLoggedIn(command):
            commandHint("Not logged in. Run:", command: command)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(Tint.red.color)
                .lineLimit(2)
                .hintWhenTruncated(message)
        }
    }

    @ViewBuilder
    private func checks(_ info: PullRequestInfo) -> some View {
        let word = info.isMergeRequest ? "pipeline" : "checks"
        switch info.checks {
        case .passing: Tag("\(word) passing", tint: .green, systemImage: "checkmark")
        case .failing: Tag("\(word) failing", tint: .red, systemImage: "xmark")
        case .pending: Tag("\(word) running", tint: .orange, systemImage: "clock")
        case .none: EmptyView()
        }
    }

    private func commandHint(_ text: String, command: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(command)
                .font(.caption.monospaced())
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 4))
            IconButton(systemImage: "doc.on.doc", help: "Copy the command") {
                toaster.copy(command, label: command)
            }
        }
    }

    private func stateTint(_ state: PullRequestInfo.State) -> Tint {
        switch state {
        case .open: .green
        case .draft: .gray
        case .merged: .purple
        case .closed: .red
        }
    }
}

#Preview {
    GitPullRequestLine()
        .padding()
        .previewEnvironment()
}
