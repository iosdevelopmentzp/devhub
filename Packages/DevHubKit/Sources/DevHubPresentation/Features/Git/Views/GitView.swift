import SwiftUI
import DevHubDomain
import DevHubUI

struct GitView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(GitStore.self) private var git
    @Environment(CommitHistoryStore.self) private var history
    @Environment(BuildStore.self) private var build
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(SettingsStore.self) private var settings
    @Environment(NewPullRequestStore.self) private var newPullRequest
    @Environment(AppActions.self) private var appActions
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(\.panelOpenCount) private var openCount

    @State private var confirmingDeleteName: String?
    @State private var confirmingSwitchName: String?
    @State private var pullRequestBranchName: String?
    @State private var launchBranchName: String?

    var body: some View {
        @Bindable var git = git
        @Bindable var history = history
        VStack(spacing: 0) {
            GitHeader()
                .padding(14)
                .background(Theme.base)
            Divider()
            ToolbarBar(verticalPadding: 7) {
                HStack {
                    Picker("Section", selection: $git.section) {
                        Text("Local \(git.state?.localBranches.count ?? 0)").tag(GitStore.Section.local)
                        Text("Remote \(git.state?.remoteBranches.count ?? 0)").tag(GitStore.Section.remote)
                        Text("History").tag(GitStore.Section.history)
                        Text("Reflog").tag(GitStore.Section.reflog)
                        Text(changesTitle).tag(GitStore.Section.changes)
                        if git.stashes.isEmpty == false {
                            Text("Stash \(git.stashes.count)").tag(GitStore.Section.stash)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    if git.section == .history {
                        Picker("Commits", selection: $history.scope) {
                            ForEach(CommitHistoryStore.Scope.allCases, id: \.self) { scope in
                                Text(scope.rawValue).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .fixedSize()
                        .hint("This branch: the commits that are not in \(git.baseName) yet. All: the last 150 commits.")
                    }
                    Spacer()
                    Text(sectionHint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .hintWhenTruncated(sectionHint)
                }
            }
            Divider()
            content
        }
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: confirmingDeleteName)
        .animation(.snappy(duration: 0.18), value: pullRequestBranchName)
        .onChange(of: git.stashes.isEmpty) { _, isEmpty in
            guard isEmpty, git.section == .stash else { return }
            git.section = .local
        }
        .task(id: openCount) {
            await git.refresh()
            git.fetchIfStale(everyMinutes: settings.values.autoFetchMinutes, now: .now)
        }
        .task(id: openCount) {
            await openPullRequests.refreshIfStale()
        }
    }

    private var filteredLocals: [GitBranch] {
        (git.state?.localBranches ?? []).filter { session.matchesSearch($0.name, $0.subject) }
    }

    private var localSections: [LocalBranchSectionModel] {
        LocalBranchSectionsMapper.sections(for: filteredLocals, currentBranch: git.currentBranch) { branch in
            LocalBranchRowMapper.model(
                for: branch,
                currentBranch: git.currentBranch,
                worktree: git.worktree(atPath: branch.worktreePath),
                openPullRequest: openPullRequests.request(forBranch: branch.name),
                baseName: git.baseName,
                changedFiles: git.snapshot?.changedFiles ?? 0,
                ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate),
                isBuildRunning: build.isRunning,
                isBusy: git.isBusy,
                configActions: branchActions
            )
        }
    }

    private var branchActions: [ConfigActionItemModel] {
        ConfigActionItemMapper.models(for: configActions.actions(for: .gitBranchRow), isRunning: configActions.isRunning)
    }

    private var stashRows: [StashRowModel] {
        git.stashes
            .filter { session.matchesSearch($0.message, $0.branch ?? "") }
            .map { StashRowMapper.model(for: $0, isBusy: git.isBusy) }
    }

    private var cleanupCandidates: [GitBranch] {
        BranchCleanupPolicy.candidates(branches: filteredLocals, currentBranch: git.currentBranch, baseName: git.baseName, protected: git.gitSettings.protectedBranches)
    }

    private var remotes: [RemoteBranchRowModel] {
        let localNames = git.localBranchNames
        return (git.state?.remoteBranches ?? [])
            .filter { session.matchesSearch($0.name, $0.subject, $0.author) }
            .map { branch in
                RemoteBranchRowMapper.model(
                    for: branch,
                    remote: git.remote,
                    localBranchNames: localNames,
                    openPullRequest: openPullRequests.request(forBranch: branch.name),
                    ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate),
                    checkoutPath: git.checkoutPath(forBranch:),
                    isBuildRunning: build.isRunning,
                    isBusy: git.isBusy
                )
            }
    }

    private var changesTitle: String {
        let count = git.snapshot?.changedFiles ?? 0
        return count > 0 ? "Changes \(count)" : "Changes"
    }

    private var sectionHint: String {
        switch git.section {
        case .local: "By your last visit, from reflog"
        case .remote: "By last commit. Search to find one."
        case .history: history.scope == .branch ? "Not in \(git.baseName) yet. Click a commit to see its files." : "Last 150 commits. Click a commit to see its files."
        case .reflog: "Where HEAD was: the last 200 moves. Lost commits stay here."
        case .changes: "Click a file to see its diff"
        case .stash: "Shared by all worktrees. Newest first."
        }
    }

    private var content: some View {
        ListState(
            failure: git.state == nil ? git.error.map { error in
                ListMessage.failure("Cannot read the repository", description: error) {
                    Task { await git.refresh() }
                }
            } : nil,
            isLoading: git.state == nil,
            loadingTitle: "Reading git…",
            empty: nil,
            noResultsFor: nil
        ) {
            sectionContent
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        if git.section == .changes {
            ChangesSection()
        } else if git.section == .history || git.section == .reflog {
            HistorySection(showsReflog: git.section == .reflog)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    switch git.section {
                    case .local:
                        ForEach(localSections) { section in
                            localSection(section)
                        }
                    case .remote:
                        ForEach(remotes) { model in
                            remoteRow(model)
                            Divider().padding(.leading, 40)
                        }
                    case .stash:
                        ForEach(stashRows) { model in
                            stashRow(model)
                            Divider().padding(.leading, 40)
                        }
                    case .history, .reflog, .changes:
                        EmptyView()
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func localSection(_ section: LocalBranchSectionModel) -> some View {
        let isMerged = section.id == .merged
        let isCollapsed = isMerged && git.isMergedCollapsed && session.searchText.isEmpty
        LocalBranchSectionHeader(
            model: section,
            isCollapsed: isCollapsed,
            cleanup: isMerged ? BranchCleanupMapper.model(for: cleanupCandidates) : nil,
            progressText: isMerged ? git.bulkDelete.map(BranchCleanupMapper.progressText) : nil,
            onToggle: isMerged ? { git.isMergedCollapsed.toggle() } : nil,
            onCleanUp: { git.deleteBranches(cleanupCandidates, forceGone: $0) }
        )
        if isCollapsed == false {
            ForEach(section.rows) { model in
                localRow(model)
                if let pending = configActions.pending(in: Placement.gitBranchRow.slot(for: model.name)) {
                    ConfigActionPrompt(pending: pending)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                }
                if newPullRequest.draft?.origin == .branch(model.name) {
                    NewPullRequestForm()
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                }
                Divider().padding(.leading, 40)
            }
        }
    }

    private func localRow(_ model: LocalBranchRowModel) -> some View {
        LocalBranchRow(
            model: model,
            isConfirmingDelete: confirmingDeleteName == model.name,
            isConfirmingSwitch: confirmingSwitchName == model.name,
            isPickingLaunch: launchBranchName == model.name,
            isShowingExistingPullRequest: pullRequestBranchName == model.name,
            onSwitch: { git.switchTo(model.name, plan: $0) },
            onRequestSwitch: {
                confirmingDeleteName = nil
                pullRequestBranchName = nil
                launchBranchName = nil
                confirmingSwitchName = model.name
            },
            onCancelSwitch: { confirmingSwitchName = nil },
            onUpdate: { update(model.id) },
            onSelectCheckout: { git.selectCheckout($0) },
            onRequestDelete: {
                pullRequestBranchName = nil
                launchBranchName = nil
                confirmingDeleteName = model.name
            },
            onCancelDelete: { confirmingDeleteName = nil },
            onDelete: { force in delete(model.id, force: force) },
            onRequestPullRequest: {
                confirmingDeleteName = nil
                launchBranchName = nil
                guard model.existingPullRequest != nil else {
                    appActions.startPullRequest(branch: model.name, origin: .branch(model.name))
                    return
                }
                pullRequestBranchName = model.name
            },
            onCancelPullRequest: { pullRequestBranchName = nil },
            onRequestLaunch: {
                confirmingDeleteName = nil
                pullRequestBranchName = nil
                launchBranchName = model.name
            },
            onCancelLaunch: { launchBranchName = nil },
            onConfigAction: { id in
                configActions.request(
                    id: id,
                    item: ActionItemContext(branch: model.name, worktreePath: model.worktreePath, rowID: model.name),
                    slot: Placement.gitBranchRow.slot(for: model.name)
                )
            }
        )
    }

    private func stashRow(_ model: StashRowModel) -> some View {
        StashRow(
            model: model,
            onApply: { stash(model.id).map(git.apply) },
            onPop: { stash(model.id).map(git.pop) },
            onDrop: { stash(model.id).map(git.drop) }
        )
    }

    private func stash(_ id: GitStash.ID) -> GitStash? {
        git.stashes.first { $0.id == id }
    }

    private func remoteRow(_ model: RemoteBranchRowModel) -> some View {
        RemoteBranchRow(model: model) {
            guard let branch = git.state?.remoteBranches.first(where: { $0.id == model.id }) else { return }
            git.checkOut(branch)
        }
    }

    private func update(_ id: GitBranch.ID) {
        guard let branch = localBranch(id) else { return }
        git.update(branch)
    }

    private func delete(_ id: GitBranch.ID, force: Bool) {
        guard let branch = localBranch(id) else { return }
        git.delete(branch, force: force)
    }

    private func localBranch(_ id: GitBranch.ID) -> GitBranch? {
        git.state?.localBranches.first { $0.id == id }
    }
}

#Preview {
    GitView()
        .previewEnvironment()
}
