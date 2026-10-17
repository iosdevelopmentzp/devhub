import SwiftUI
import DevHubUI

struct PullRequestDetailsView: View {
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let model: PullRequestDetailsModel
    let actions: PullRequestDetailActions

    var body: some View {
        Group {
            switch model.content {
            case .loading:
                ProgressView("Reading the \(words.request)…")
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            case .failure(let message):
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("Retry", action: actions.retry)
                        .controlSize(.small)
                }
            case .loaded(let loaded):
                loadedContent(loaded)
            }
        }
        .padding(10)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadedContent(_ loaded: PullRequestDetailsModel.Loaded) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if loaded.pipelineTag != nil || actions.openWindow != nil {
                HStack(spacing: 8) {
                    if let pipeline = loaded.pipelineTag {
                        Button {
                            appActions.open(loaded.pipelineURL)
                        } label: {
                            ModelTag(model: pipeline)
                        }
                        .buttonStyle(.plain)
                    }
                    if let duration = loaded.pipelineDurationText {
                        Text(duration)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if loaded.canCancelPipeline {
                        Button(words.cancelChecksTitle, systemImage: "stop.circle", action: actions.cancelPipeline)
                            .controlSize(.small)
                            .fixedSize()
                            .hint("Stop the running \(words.checks) of the last commit")
                    }
                    Spacer(minLength: 4)
                    if let onOpenWindow = actions.openWindow {
                        Button("Open in Window", systemImage: "macwindow", action: onOpenWindow)
                            .controlSize(.small)
                            .fixedSize()
                            .hint("Open this \(words.request) in its own window that stays open after the panel closes")
                    }
                }
            }
            if loaded.failedJobs.isEmpty == false {
                FlowLayout(spacing: 6) {
                    Text("Failed:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                    ForEach(loaded.failedJobs, id: \.self) { job in
                        Button(job.title) {
                            appActions.open(job.url)
                        }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .disabled(job.url == nil)
                        .hint("Open the \(words.job) log in \(words.name)")
                    }
                }
            }
            if let description = loaded.description {
                ExpandableText(description, lineLimit: 12)
                    .font(.callout)
            }
            section(loaded.threadsTitle, fixThreads: loaded.canFixThreads) {
                ForEach(loaded.threads) { thread in
                    ReviewThreadRow(
                        model: thread,
                        onShowInDiff: { actions.showInDiff(thread.id) },
                        onOpenFile: { actions.openFile(thread.filePath ?? "", thread.line) },
                        onResolve: { actions.resolveThread(thread.id) },
                        onReply: { actions.reply(thread.id, $0) }
                    )
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                filesHeader(loaded)
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(loaded.files) { file in
                        PullRequestFileRow(model: file, actions: actions)
                        .id(PullRequestFileRowModel.scrollID(file.id))
                    }
                }
            }
        }
    }

    private func filesHeader(_ loaded: PullRequestDetailsModel.Loaded) -> some View {
        HStack(spacing: 10) {
            Text(loaded.filesTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            if loaded.hasThreadsInDiff {
                Menu {
                    Toggle("Show Threads in the Diff", isOn: Binding(get: { loaded.showsThreadsInDiff }, set: { _ in actions.toggleThreadsInDiff() }))
                    Divider()
                    Button("Open All Threads", systemImage: "text.bubble", action: actions.openAllDiffThreads)
                    Button("Fold All Threads", systemImage: "bubble.left", action: actions.foldAllDiffThreads)
                } label: {
                    Label("Threads", systemImage: loaded.showsThreadsInDiff ? "bubble.left.fill" : "bubble.left")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .hint("Threads show under their line in the diff, folded to one line. Hide them all, or open or fold them all.")
            }
            Button("Expand All", systemImage: "rectangle.expand.vertical", action: actions.expandAllFiles)
                .disabled(loaded.canExpandAllFiles == false)
                .hint("Open the diff of every file that is not marked as viewed")
            Button("Collapse All", systemImage: "rectangle.compress.vertical", action: actions.collapseAllFiles)
                .disabled(loaded.canCollapseAllFiles == false)
                .hint("Fold every open diff")
        }
        .buttonStyle(LinkButtonStyle(.accent))
        .font(.caption)
    }

    private func section<Content: View>(_ title: String, fixThreads: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if fixThreads {
                    Button("Fix with Claude…", systemImage: "sparkles", action: actions.fixThreads)
                        .buttonStyle(LinkButtonStyle(.accent))
                        .font(.caption)
                        .fixedSize()
                        .hint("Write the open threads into a prompt and start Claude in Terminal, in the worktree of the source branch. DevHub creates the worktree when there is none.")
                }
            }
            content()
        }
    }
}

#Preview {
    PullRequestDetailsView(model: .preview, actions: .preview)
        .previewEnvironment()
        .padding()
        .frame(width: 680)
}
