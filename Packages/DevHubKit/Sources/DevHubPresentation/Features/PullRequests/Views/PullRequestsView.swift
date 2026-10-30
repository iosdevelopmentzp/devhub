import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(PullRequestDetailStore.self) private var detailStore
    @Environment(Toaster.self) private var toaster
    @Environment(\.panelOpenCount) private var openCount
    @Environment(\.openPullRequestWindow) private var openPullRequestWindow
    @Environment(AppActions.self) private var appActions
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SettingsStore.self) private var settings
    @Environment(NewPullRequestStore.self) private var newPullRequest
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(\.codeHostWords) private var words

    @State private var launchID: PullRequestSummary.ID?
    @State private var dragFraction: CGFloat?
    @State private var dragStartWidth: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            PullRequestsToolbar(count: visible.count)
            Divider()
            if pullRequests.filter.isActive {
                PullRequestsFilterBar(
                    chips: PullRequestFilterChipMapper.chips(for: pullRequests.filter),
                    onRemove: { pullRequests.removeFilter($0) },
                    onClear: { pullRequests.clearFilter() }
                )
                Divider()
            }
            if newPullRequest.draft?.origin == .pullRequests {
                NewPullRequestForm()
                    .padding(14)
                Divider()
            }
            if let error = pullRequests.error, pullRequests.requests.isEmpty == false {
                NoticeBar("Cannot read \(words.requests): \(error.localizedDescription)", actionTitle: "Retry") {
                    Task { await pullRequests.refresh() }
                }
                Divider()
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
        .task(id: "\(openCount)#\(pullRequests.query.scope.rawValue)#\(pullRequests.query.state.rawValue)") {
            await pullRequests.refreshIfStale()
        }
        .task(id: "\(openCount)#\(pullRequests.scope.rawValue)") {
            pullRequests.beginVisit(now: .now)
        }
        .task(id: openCount) {
            guard git.state == nil else { return }
            await git.refresh()
        }
    }

    private var visible: [PullRequestRowModel] {
        pullRequests.visible
            .filter { session.matchesSearch($0.title, words.reference($0.iid), $0.author, $0.sourceBranch, $0.targetBranch, $0.labels.joined(separator: " ")) }
            .map { styled(PullRequestRowMapper.model(for: $0, context: context, local: localState($0.sourceBranch), isBusy: pullRequests.isBusy($0.id), isExpanded: $0.id == pullRequests.expandedID, configActions: rowActions)) }
    }

    private var rowActions: [ConfigActionItemModel] {
        ConfigActionItemMapper.models(for: configActions.actions(for: .pullRequestsRow), isRunning: configActions.isRunning)
    }

    private func styled(_ model: PullRequestRowModel) -> PullRequestRowModel {
        pullRequests.listStyle == .detailed ? model : PullRequestCalmStyleMapper.calm(model)
    }

    private var context: PullRequestRowContext {
        PullRequestRowContext(username: pullRequests.username, scope: pullRequests.scope, seenAt: pullRequests.seenAt, now: .now, isMainCheckoutClean: git.isMainCheckoutClean, ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate), words: words, staleDays: git.gitSettings.pullRequests.staleDays)
    }

    private func localState(_ branch: String) -> PullRequestLocalState {
        PullRequestLocalStateMapper.state(for: branch, checkout: git, worktrees: worktrees)
    }

    private var content: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let layout = PullRequestsLayout.layout(forWidth: width, listFraction: dragFraction ?? CGFloat(pullRequests.listFraction))
            if case .split(let listWidth) = layout {
                HStack(spacing: 0) {
                    list(layout)
                        .frame(width: listWidth)
                    SplitHandle(
                        onDrag: { translation in
                            let start = dragStartWidth ?? listWidth
                            dragStartWidth = start
                            dragFraction = PullRequestsLayout.fraction(forListWidth: start + translation, in: width)
                        },
                        onEnd: {
                            if let dragFraction {
                                pullRequests.listFraction = Double(dragFraction)
                            }
                            dragFraction = nil
                            dragStartWidth = nil
                        }
                    )
                    .hint("Drag to change the width of the list")
                    detailsPane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                list(layout)
            }
        }
    }

    private func list(_ layout: PullRequestsLayout) -> some View {
        ListState(
            failure: pullRequests.requests.isEmpty ? pullRequests.error.map(failure) : nil,
            isLoading: pullRequests.hasLoaded == false,
            loadingTitle: "Reading \(words.requests)…",
            empty: pullRequests.visible.isEmpty ? emptyMessage : nil,
            noResultsFor: visible.isEmpty ? session.searchText : nil
        ) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visible) { model in
                            row(model, isSplit: layout.isSplit)
                            if let pending = configActions.pending(in: Placement.pullRequestsRow.slot(for: String(model.id))) {
                                ConfigActionPrompt(pending: pending)
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 8)
                            }
                            Divider()
                                .padding(.leading, 40)
                        }
                        if pullRequests.hasMore {
                            loadMore
                        }
                    }
                    .padding(.bottom, 8)
                }
                .environment(\.diffScrollProxy, proxy)
                .onChange(of: pullRequests.revealedID) { _, id in
                    guard let id else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
                .onChange(of: detailStore.focus) { _, focus in
                    guard let focus, layout.isSplit == false else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(PullRequestFileRowModel.scrollID(focus.path), anchor: .top)
                    }
                }
            }
        }
    }

    private var detailsPane: some View {
        let summary = pullRequests.expandedID.flatMap(pullRequests.request(id:))
        return PullRequestDetailsPane(
            model: summary.map { styled(PullRequestRowMapper.model(for: $0, context: context, local: localState($0.sourceBranch), isBusy: pullRequests.isBusy($0.id), isExpanded: true, configActions: rowActions)) },
            details: summary.map(details(for:)),
            isPickingLaunch: summary.map { launchID == $0.id } ?? false,
            detailActions: summary.map(detailActions(for:)) ?? .preview,
            onRequestLaunch: { launchID = summary?.id },
            onCancelLaunch: { launchID = nil },
            onAction: { kind in
                guard let id = summary?.id else { return }
                pullRequests.perform(kind, on: id)
            },
            onMerge: { kind, squash, remove in
                guard let id = summary?.id else { return }
                pullRequests.merge(id, kind: kind, squash: squash, removeSourceBranch: remove)
            }
        )
        .task(id: summary?.id) {
            guard let id = summary?.id else { return }
            await detailStore.load(id)
        }
    }

    private var loadMore: some View {
        HStack(spacing: 8) {
            Spacer()
            if pullRequests.isLoadingMore {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Load \(words.pageSize) more", systemImage: "arrow.down.circle") {
                Task { await pullRequests.loadMore() }
            }
            .controlSize(.small)
            .disabled(pullRequests.isLoadingMore)
            .hint("\(words.hostTitle) sends \(words.pageSize) \(words.requests) at a time. Search and filters work on the loaded ones.")
            Spacer()
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func row(_ model: PullRequestRowModel, isSplit: Bool) -> some View {
        if pullRequests.listStyle == .compact, isSplit || model.isExpanded == false, let summary = pullRequests.request(id: model.id) {
            PullRequestCompactRow(
                model: PullRequestCompactRowMapper.model(for: summary, row: model, context: context),
                isSelected: model.isExpanded,
                onToggle: { pullRequests.toggleExpanded(model.id) }
            )
        } else {
            fullRow(model, isSplit: isSplit)
        }
    }

    private func fullRow(_ model: PullRequestRowModel, isSplit: Bool) -> some View {
        let summary = pullRequests.request(id: model.id)
        return PullRequestRow(
            model: model,
            details: model.isExpanded && isSplit == false ? summary.map(details(for:)) : nil,
            isSelected: model.isExpanded && isSplit,
            isNarrow: isSplit,
            isPickingLaunch: launchID == model.id && (isSplit && model.isExpanded) == false,
            detailActions: summary.map(detailActions(for:)) ?? .preview,
            onToggle: { pullRequests.toggleExpanded(model.id) },
            onRequestLaunch: { launchID = model.id },
            onCancelLaunch: { launchID = nil },
            onAction: { pullRequests.perform($0, on: model.id) },
            onMerge: { pullRequests.merge(model.id, kind: $0, squash: $1, removeSourceBranch: $2) },
            onLabel: { pullRequests.toggleLabel($0) }
        )
        .task(id: model.isExpanded) {
            guard model.isExpanded else { return }
            await detailStore.load(model.id)
        }
    }

    private func detailActions(for summary: PullRequestSummary) -> PullRequestDetailActions {
        PullRequestDetailActions.live(for: summary, detailStore: detailStore, pullRequests: pullRequests, appActions: appActions, configActions: configActions, openWindow: openPullRequestWindow)
    }

    private func details(for summary: PullRequestSummary) -> PullRequestDetailsModel {
        let id = summary.id
        return PullRequestDetailsMapper.model(
            summary: summary,
            details: detailStore.details[id],
            diffs: detailStore.diffs[id],
            error: detailStore.errors[id],
            review: detailStore.review(of: id),
            words: words
        )
    }

    private func failure(_ error: PullRequestError) -> ListMessage {
        if case .notLoggedIn(let tool, let host) = error {
            let command = "\(tool) auth login --hostname \(host)"
            return ListMessage.failure(
                "\(tool) is not logged in",
                description: "Run \(command) in Terminal, then retry.",
                actionTitle: "Copy Command"
            ) {
                toaster.copy(command, label: "Login command")
            }
        }
        return ListMessage.failure("Cannot read \(words.requests)", description: error.localizedDescription) {
            Task { await pullRequests.refresh() }
        }
    }

    private var emptyMessage: ListMessage {
        ListMessage(
            "No \(words.requests)",
            systemImage: "arrow.triangle.pull",
            description: pullRequests.filter.isActive
                ? "Nothing matches the filters. Clear them in the filter menu."
                : "Nothing matches \(pullRequests.scope.title) · \(pullRequests.query.state.title)."
        )
    }
}

#Preview {
    PullRequestsView()
        .previewEnvironment()
}
