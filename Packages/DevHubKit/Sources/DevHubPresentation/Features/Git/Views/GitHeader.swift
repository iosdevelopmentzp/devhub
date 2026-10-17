import SwiftUI
import DevHubDomain
import DevHubUI

struct GitHeader: View {
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(BranchPullRequestStore.self) private var branchPullRequest
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(AppActions.self) private var appActions
    @Environment(SettingsStore.self) private var settings
    @Environment(NewPullRequestStore.self) private var newPullRequest
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(\.codeHostWords) private var words

    @State private var confirming: Confirmation?

    @State private var stashMessage = ""

    enum Confirmation {
        case forcePush
        case rebase
        case stash
    }

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                topLine
                if let snapshot = git.snapshot {
                    let model = GitHeaderMapper.model(for: snapshot, baseName: git.baseName, ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate), words: words)
                    branchLine(model)
                    if model.showsPullRequestLine {
                        pullRequestLine
                    }
                    if let operationText = model.operationText {
                        operationBanner(operationText, canContinue: model.canContinueOperation)
                    }
                    actions(model)
                    ConfigActionResults(placement: .gitPills, slot: Placement.gitPills.slot)
                    if let confirming {
                        confirmation(confirming, model: model)
                    }
                    if newPullRequest.draft?.origin == .header {
                        NewPullRequestForm()
                    }
                }
            }
        }
        .animation(.snappy(duration: 0.18), value: confirming)
    }

    private var topLine: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(worktrees.availableCheckouts) { worktree in
                    Button(GitHeaderMapper.checkoutTitle(worktree)) {
                        git.selectCheckout(worktree.path)
                    }
                }
            } label: {
                Label(checkoutLabel, systemImage: "folder")
            }
            .fixedSize()
            .hint("Which checkout the actions below run in")
            Spacer()
            if let busy = git.busyTitle {
                ProgressView()
                    .controlSize(.mini)
                Text(busy + "…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let fetched = git.snapshot?.lastFetch {
                Text(GitHeaderMapper.fetchedText(fetched))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            IconButton(systemImage: "arrow.clockwise", help: "Re-read the repository") {
                Task { await git.refresh() }
            }
            .disabled(git.isLoading)
        }
        .controlSize(.small)
    }

    private var checkoutLabel: String {
        let path = git.checkoutPath
        return GitHeaderMapper.checkoutLabel(path: path, worktree: worktrees.worktree(atPath: path))
    }

    private var pullRequestLine: some View {
        PullRequestLine(
            model: PullRequestLineMapper.model(
                status: branchPullRequest.status,
                error: branchPullRequest.error,
                isLoading: branchPullRequest.isLoading,
                openRequest: git.currentBranch.flatMap(openPullRequests.request(forBranch:)),
                username: openPullRequests.username,
                words: words
            ),
            terminalPath: git.checkoutPath,
            onRefresh: { Task { await branchPullRequest.refresh() } }
        )
        .task(id: git.snapshot?.branch) {
            await branchPullRequest.refreshIfStale()
        }
    }

    private func branchLine(_ model: GitHeaderModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundStyle(.indigo)
                Text(model.branchTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .copyOnClick(model.branchCopyValue, label: model.branchCopyValue)
                Text(model.head)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .copyOnClick(model.head, label: model.head)
            }
            FlowLayout(spacing: 6, lineSpacing: 4) {
                if let ticket = model.ticket {
                    TicketChip(model: ticket)
                }
                ModelTag(model: model.statusTag)
                if let upstreamTag = model.upstreamTag {
                    ModelTag(model: upstreamTag)
                        .copyOnClick(upstreamTag.text, label: upstreamTag.text)
                }
                ForEach(model.tags, id: \.self) { tag in
                    ModelTag(model: tag)
                }
                if let stashTag = model.stashTag {
                    Button {
                        git.section = .stash
                    } label: {
                        ModelTag(model: stashTag)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func operationBanner(_ text: String, canContinue: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
            Spacer()
            Button("Terminal") {
                appActions.openTerminal(at: git.checkoutPath)
            }
            if canContinue {
                Button("Continue") {
                    git.continueRebase()
                }
            }
            Button("Abort", role: .destructive) {
                git.abortOperation()
            }
        }
        .controlSize(.small)
        .padding(8)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func actions(_ model: GitHeaderModel) -> some View {
        HStack(spacing: 6) {
            ActionBar(items: model.actions.map(actionItem) + configItems)
            Spacer(minLength: 0)
            IconButton(systemImage: "terminal", help: "Open this checkout in the terminal") {
                appActions.openTerminal(at: git.checkoutPath)
            }
            if let branch = model.webBranch {
                IconButton(systemImage: "arrow.triangle.pull", help: model.newPullRequestHint) {
                    appActions.startPullRequest(branch: branch, origin: .header)
                }
                IconButton(systemImage: "globe", help: model.branchOnWebHint) {
                    appActions.openBranchOnWeb(branch)
                }
            }
        }
        .controlSize(.small)
        .disabled(git.isBusy)
    }

    private var configItems: [ActionItem] {
        ConfigActionItemMapper.models(for: configActions.actions(for: .gitPills), isRunning: configActions.isRunning)
            .map { $0.actionItem(priority: 1, onRun: runConfigAction) }
    }

    private func runConfigAction(_ id: String) {
        configActions.request(
            id: id,
            item: ActionItemContext(branch: git.currentBranch, worktreePath: git.checkoutPath),
            slot: Placement.gitPills.slot
        )
    }

    private func actionItem(_ action: GitHeaderActionModel) -> ActionItem {
        ActionItem(
            action.title,
            systemImage: action.systemImage,
            hint: action.hint,
            priority: action.priority,
            isDisabled: action.isDisabled
        ) {
            perform(action.id)
        }
    }

    private func perform(_ action: GitHeaderAction) {
        switch action {
        case .fetch:
            git.fetch()
        case .pull:
            git.pull()
        case .push:
            git.push()
        case .forcePush:
            confirming = .forcePush
        case .rebase:
            confirming = .rebase
        case .updateBase:
            git.updateBase()
        case .stash:
            stashMessage = ""
            confirming = .stash
        case .popStash:
            git.popStash()
        }
    }

    @ViewBuilder
    private func confirmation(_ kind: Confirmation, model: GitHeaderModel) -> some View {
        if kind == .stash {
            stashField
        } else {
            InlineConfirmation(
                kind == .forcePush ? model.forcePushMessage : model.rebaseMessage,
                confirmTitle: kind == .forcePush ? "Force Push" : "Rebase",
                confirmRole: nil,
                tint: kind == .forcePush ? .red : .orange,
                onCancel: { confirming = nil },
                onConfirm: {
                    confirming = nil
                    if kind == .forcePush {
                        git.forcePush()
                    } else {
                        git.rebaseOnBase()
                    }
                }
            )
        }
    }

    private var stashField: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.and.arrow.down")
                .foregroundStyle(.secondary)
            TextField("Message (optional)", text: $stashMessage)
                .textFieldStyle(.roundedBorder)
                .onSubmit(stash)
            Button("Cancel") { confirming = nil }
            Button("Stash", action: stash)
        }
        .controlSize(.small)
    }

    private func stash() {
        confirming = nil
        git.stash(message: stashMessage)
    }
}

#Preview {
    GitHeader()
        .padding()
        .previewEnvironment()
}
