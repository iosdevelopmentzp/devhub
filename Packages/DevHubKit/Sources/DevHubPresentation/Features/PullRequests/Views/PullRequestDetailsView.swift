import SwiftUI
import DevHubUI

struct PullRequestDetailsView: View {
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    let model: PullRequestDetailsModel
    let actions: PullRequestDetailActions

    @State private var confirmingCancelWorkflowID: String?

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
            if let notice = loaded.ciNotice {
                NoticeBar(notice.text, systemImage: "wrench.and.screwdriver", tint: .orange, actionTitle: "Run in Terminal") {
                    actions.runCISetup(notice.command)
                }
                .hint(notice.command)
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
            if loaded.jobGroups.isEmpty == false {
                jobs(loaded)
            }
            if loaded.reviewLines.isEmpty == false {
                review(loaded.reviewLines)
            }
            if let description = loaded.description {
                ExpandableText(description, lineLimit: 12)
                    .font(.callout)
            }
            section(loaded.threadsTitle, fixThreads: loaded.canFixThreads) {
                ForEach(loaded.threads) { thread in
                    ReviewThreadRow(
                        model: thread,
                        expandsReplies: false,
                        onShowInDiff: { actions.showInDiff(thread.id) },
                        onOpenFile: { actions.openFile(thread.filePath ?? "", thread.line) },
                        onResolve: { actions.resolveThread(thread.id) },
                        onReply: { actions.reply(thread.id, $0) }
                    )
                }
                PullRequestCommentBox(model: loaded.commentBox, onChange: actions.setCommentDraft, onSend: actions.sendComment)
            }
            VStack(alignment: .leading, spacing: 6) {
                filesHeader(loaded)
                if let suggestion = loaded.hideSuggestion {
                    hideSuggestionLine(suggestion)
                }
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(loaded.files) { file in
                        PullRequestFileRow(model: file, actions: actions)
                        .id(PullRequestFileRowModel.scrollID(file.id))
                    }
                }
            }
        }
    }

    private func jobs(_ loaded: PullRequestDetailsModel.Loaded) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(loaded.jobsTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 4)
                if let autoRerun = loaded.autoRerun {
                    autoRerunControl(autoRerun)
                }
            }
            ForEach(loaded.jobGroups) { group in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = group.title {
                        groupHeader(group, title: title)
                    }
                    if let workflowID = group.workflowID, confirmingCancelWorkflowID == workflowID {
                        InlineConfirmation(
                            "Cancel the workflow \(title(of: group))? Its running jobs stop.",
                            confirmTitle: "Cancel Workflow",
                            confirmRole: .destructive,
                            onCancel: { confirmingCancelWorkflowID = nil },
                            onConfirm: {
                                confirmingCancelWorkflowID = nil
                                actions.cancelWorkflow(workflowID)
                            }
                        )
                        .padding(.leading, 12)
                    }
                    ForEach(group.jobs) { job in
                        PipelineJobRow(
                            model: job,
                            onToggleLog: { job.jobID.map(actions.toggleJobLog) },
                            onRetry: { job.jobID.map { actions.retryJob($0, job.title) } },
                            onApprove: { job.jobID.map { actions.approveJob($0, job.title) } },
                            onToggleDetails: { actions.toggleJobDetails(job.id) },
                            onToggleTestMessage: actions.toggleTestMessage
                        )
                        .padding(.leading, group.title == nil ? 0 : 12)
                    }
                }
            }
            if let historyTitle = loaded.ciHistoryTitle {
                ciHistory(loaded, title: historyTitle)
            }
        }
        .animation(.snappy(duration: 0.18), value: confirmingCancelWorkflowID)
        .animation(.snappy(duration: 0.18), value: loaded.showsCIHistory)
    }

    @ViewBuilder
    private func autoRerunControl(_ model: PullRequestDetailsModel.AutoRerun) -> some View {
        if model.isOn {
            Button(model.title, systemImage: model.icon, action: actions.stopAutoRerun)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .fixedSize()
                .hint(model.hint)
        } else {
            Menu {
                ForEach(model.choices, id: \.self) { choice in
                    Button(choice.title) {
                        actions.startAutoRerun(choice.count)
                    }
                }
            } label: {
                Label(model.title, systemImage: model.icon)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .hint(model.hint)
        }
    }

    private func ciHistory(_ loaded: PullRequestDetailsModel.Loaded, title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    actions.toggleCIHistory()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: loaded.showsCIHistory ? "chevron.down" : "chevron.right")
                            .font(.caption2.weight(.semibold))
                        Text(title)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .hint("The CircleCI workflows DevHub read for this \(words.request) before, with their failed tests")
                if loaded.showsCIHistory {
                    Button("Forget") {
                        actions.clearCIHistory()
                    }
                    .buttonStyle(LinkButtonStyle(.secondary))
                    .hint("Remove the saved runs of this \(words.request) from DevHub")
                }
            }
            if loaded.showsCIHistory {
                ForEach(loaded.ciHistory) { record in
                    CIHistoryRow(model: record, onToggle: { actions.toggleCIHistoryRun(record.id) }, onToggleTestMessage: actions.toggleTestMessage)
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.top, 4)
    }

    private func groupHeader(_ group: PipelineJobGroupModel, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: group.icon)
                .font(.caption2)
                .foregroundStyle(group.tint.color)
                .frame(width: 16)
            Text(title)
                .font(.caption.weight(.semibold))
            if let sourceText = group.sourceText {
                PlainTag(sourceText, systemImage: "circle.dotted.circle")
                    .hint("The jobs of this workflow come from the circleci tool")
            }
            Text(group.statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if group.workflowID != nil {
                Spacer(minLength: 4)
                if group.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }
                if let workflowID = group.workflowID, group.canRerunFailed {
                    Button("Re-run Failed", systemImage: "arrow.clockwise") {
                        actions.rerunWorkflow(workflowID, true)
                    }
                    .hint(group.rerunFailedHint)
                }
                if let workflowID = group.workflowID, group.canRerunAll {
                    Button("Re-run All", systemImage: "arrow.counterclockwise") {
                        actions.rerunWorkflow(workflowID, false)
                    }
                    .hint(group.rerunAllHint)
                }
                if let workflowID = group.workflowID, group.canCancel {
                    Button("Cancel", systemImage: "stop.circle") {
                        confirmingCancelWorkflowID = workflowID
                    }
                    .disabled(confirmingCancelWorkflowID == workflowID)
                    .hint(group.cancelHint)
                }
            }
        }
        .buttonStyle(LinkButtonStyle(.accent))
        .font(.caption)
        .padding(.top, 4)
        .hint(group.workflowID == nil ? "Stage \(title): \(group.statusText)" : "Workflow \(title): \(group.statusText)")
    }

    private func title(of group: PipelineJobGroupModel) -> String {
        group.title ?? "CircleCI"
    }

    private func review(_ lines: [PullRequestReviewLineModel]) -> some View {
        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 10, verticalSpacing: 6) {
            ForEach(lines) { line in
                GridRow {
                    Text(line.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                    FlowLayout(spacing: 6) {
                        ForEach(line.tags, id: \.self) { tag in
                            ModelTag(model: tag)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func hideSuggestionLine(_ suggestion: PullRequestDetailsModel.HideSuggestion) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(suggestion.text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(suggestion.actionTitle) {
                actions.hideFiles(suggestion.paths)
            }
            .buttonStyle(LinkButtonStyle(.accent, weight: .medium))
            .fixedSize()
            .hint(suggestion.hint)
        }
    }

    private func filesHeader(_ loaded: PullRequestDetailsModel.Loaded) -> some View {
        HStack(spacing: 10) {
            Text(loaded.filesTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer(minLength: 4)
            if let hiddenFilesTitle = loaded.hiddenFilesTitle {
                Button(hiddenFilesTitle, systemImage: loaded.showsHiddenFiles ? "eye.slash" : "eye", action: actions.toggleHiddenFiles)
                    .hint(loaded.hiddenFilesHint)
            }
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
            Button("Expand All", systemImage: "rectangle.expand.vertical") {
                actions.expandAllFiles(Set(loaded.files.map(\.id)))
            }
            .disabled(loaded.canExpandAllFiles == false)
            .hint("Open the diff of every listed file that is not marked as viewed")
            Button("Collapse All", systemImage: "rectangle.compress.vertical", action: actions.collapseAllFiles)
                .disabled(loaded.canCollapseAllFiles == false)
                .hint("Fold every open diff")
        }
        .buttonStyle(LinkButtonStyle(.accent))
        .font(.caption)
    }

    private func section<Content: View>(_ title: String, fixThreads: Bool, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if fixThreads {
                    AIProviderMenu(title: "Fix with AI", systemImage: "sparkles", hint: "Writes the open threads into a prompt file and starts the tool in the terminal, in the worktree of the source branch. DevHub creates the worktree when there is none.", onPick: actions.fixThreads)
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
