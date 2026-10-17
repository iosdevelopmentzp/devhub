import SwiftUI
import DevHubDomain
import DevHubUI

struct GitLabView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(GitLabStore.self) private var gitLab
    @Environment(MergeRequestDetailStore.self) private var detailStore
    @Environment(Toaster.self) private var toaster
    @Environment(\.panelOpenCount) private var openCount
    @Environment(\.openMergeRequestWindow) private var openMergeRequestWindow
    @Environment(AppActions.self) private var appActions
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SettingsStore.self) private var settings
    @Environment(NewMergeRequestStore.self) private var newMergeRequest

    @State private var launchID: MergeRequestSummary.ID?
    @State private var dragFraction: CGFloat?
    @State private var dragStartWidth: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            GitLabToolbar(count: visible.count)
            Divider()
            if gitLab.filter.isActive {
                GitLabFilterBar(
                    chips: MergeRequestFilterChipMapper.chips(for: gitLab.filter),
                    onRemove: { gitLab.removeFilter($0) },
                    onClear: { gitLab.clearFilter() }
                )
                Divider()
            }
            if newMergeRequest.draft?.origin == .gitLab {
                NewMergeRequestForm()
                    .padding(14)
                Divider()
            }
            if let error = gitLab.error, gitLab.requests.isEmpty == false {
                NoticeBar("Cannot read merge requests: \(error.localizedDescription)", actionTitle: "Retry") {
                    Task { await gitLab.refresh() }
                }
                Divider()
            }
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
        .task(id: "\(openCount)#\(gitLab.query.scope.rawValue)#\(gitLab.query.state.rawValue)") {
            await gitLab.refreshIfStale()
        }
        .task(id: "\(openCount)#\(gitLab.scope.rawValue)") {
            gitLab.beginVisit(now: .now)
        }
        .task(id: openCount) {
            guard git.state == nil else { return }
            await git.refresh()
        }
    }

    private var visible: [MergeRequestRowModel] {
        gitLab.visible
            .filter { session.matchesSearch($0.title, "!\($0.iid)", $0.author, $0.sourceBranch, $0.targetBranch, $0.labels.joined(separator: " ")) }
            .map { styled(MergeRequestRowMapper.model(for: $0, context: context, local: localState($0.sourceBranch), isBusy: gitLab.isBusy($0.id), isExpanded: $0.id == gitLab.expandedID)) }
    }

    private func styled(_ model: MergeRequestRowModel) -> MergeRequestRowModel {
        gitLab.listStyle == .detailed ? model : MergeRequestCalmStyleMapper.calm(model)
    }

    private var context: MergeRequestRowContext {
        MergeRequestRowContext(username: gitLab.username, scope: gitLab.scope, seenAt: gitLab.seenAt, now: .now, isMainCheckoutClean: git.isMainCheckoutClean, ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate))
    }

    private func localState(_ branch: String) -> MergeRequestLocalState {
        MergeRequestLocalStateMapper.state(for: branch, checkout: git, worktrees: worktrees)
    }

    private var content: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let layout = GitLabLayout.layout(forWidth: width, listFraction: dragFraction ?? CGFloat(gitLab.listFraction))
            if case .split(let listWidth) = layout {
                HStack(spacing: 0) {
                    list(layout)
                        .frame(width: listWidth)
                    SplitHandle(
                        onDrag: { translation in
                            let start = dragStartWidth ?? listWidth
                            dragStartWidth = start
                            dragFraction = GitLabLayout.fraction(forListWidth: start + translation, in: width)
                        },
                        onEnd: {
                            if let dragFraction {
                                gitLab.listFraction = Double(dragFraction)
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

    private func list(_ layout: GitLabLayout) -> some View {
        ListState(
            failure: gitLab.requests.isEmpty ? gitLab.error.map(failure) : nil,
            isLoading: gitLab.hasLoaded == false,
            loadingTitle: "Reading merge requests…",
            empty: gitLab.visible.isEmpty ? emptyMessage : nil,
            noResultsFor: visible.isEmpty ? session.searchText : nil
        ) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(visible) { model in
                            row(model, isSplit: layout.isSplit)
                            Divider()
                                .padding(.leading, 40)
                        }
                        if gitLab.hasMore {
                            loadMore
                        }
                    }
                    .padding(.bottom, 8)
                }
                .environment(\.diffScrollProxy, proxy)
                .onChange(of: gitLab.revealedID) { _, id in
                    guard let id else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
                .onChange(of: detailStore.focus) { _, focus in
                    guard let focus, layout.isSplit == false else { return }
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(MergeRequestFileRowModel.scrollID(focus.path), anchor: .top)
                    }
                }
            }
        }
    }

    private var detailsPane: some View {
        let summary = gitLab.expandedID.flatMap(gitLab.request(id:))
        return MergeRequestDetailsPane(
            model: summary.map { styled(MergeRequestRowMapper.model(for: $0, context: context, local: localState($0.sourceBranch), isBusy: gitLab.isBusy($0.id), isExpanded: true)) },
            details: summary.map(details(for:)),
            isPickingLaunch: summary.map { launchID == $0.id } ?? false,
            detailActions: summary.map(detailActions(for:)) ?? .preview,
            onRequestLaunch: { launchID = summary?.id },
            onCancelLaunch: { launchID = nil },
            onAction: { kind in
                guard let id = summary?.id else { return }
                gitLab.perform(kind, on: id)
            },
            onMerge: { kind, squash, remove in
                guard let id = summary?.id else { return }
                gitLab.merge(id, kind: kind, squash: squash, removeSourceBranch: remove)
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
            if gitLab.isLoadingMore {
                ProgressView()
                    .controlSize(.small)
            }
            Button("Load 100 more", systemImage: "arrow.down.circle") {
                Task { await gitLab.loadMore() }
            }
            .controlSize(.small)
            .disabled(gitLab.isLoadingMore)
            .hint("GitLab sends 100 merge requests at a time. Search and filters work on the loaded ones.")
            Spacer()
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func row(_ model: MergeRequestRowModel, isSplit: Bool) -> some View {
        if gitLab.listStyle == .compact, isSplit || model.isExpanded == false, let summary = gitLab.request(id: model.id) {
            MergeRequestCompactRow(
                model: MergeRequestCompactRowMapper.model(for: summary, row: model, context: context),
                isSelected: model.isExpanded,
                onToggle: { gitLab.toggleExpanded(model.id) }
            )
        } else {
            fullRow(model, isSplit: isSplit)
        }
    }

    private func fullRow(_ model: MergeRequestRowModel, isSplit: Bool) -> some View {
        let summary = gitLab.request(id: model.id)
        return MergeRequestRow(
            model: model,
            details: model.isExpanded && isSplit == false ? summary.map(details(for:)) : nil,
            isSelected: model.isExpanded && isSplit,
            isNarrow: isSplit,
            isPickingLaunch: launchID == model.id && (isSplit && model.isExpanded) == false,
            detailActions: summary.map(detailActions(for:)) ?? .preview,
            onToggle: { gitLab.toggleExpanded(model.id) },
            onRequestLaunch: { launchID = model.id },
            onCancelLaunch: { launchID = nil },
            onAction: { gitLab.perform($0, on: model.id) },
            onMerge: { gitLab.merge(model.id, kind: $0, squash: $1, removeSourceBranch: $2) }
        )
        .task(id: model.isExpanded) {
            guard model.isExpanded else { return }
            await detailStore.load(model.id)
        }
    }

    private func detailActions(for summary: MergeRequestSummary) -> MergeRequestDetailActions {
        MergeRequestDetailActions.live(for: summary, detailStore: detailStore, gitLab: gitLab, appActions: appActions, openWindow: openMergeRequestWindow)
    }

    private func details(for summary: MergeRequestSummary) -> MergeRequestDetailsModel {
        let id = summary.id
        return MergeRequestDetailsMapper.model(
            summary: summary,
            details: detailStore.details[id],
            diffs: detailStore.diffs[id],
            error: detailStore.errors[id],
            review: detailStore.review(of: id)
        )
    }

    private func failure(_ error: MergeRequestError) -> ListMessage {
        if case .notLoggedIn(let host) = error {
            let command = "glab auth login --hostname \(host)"
            return ListMessage.failure(
                "glab is not logged in",
                description: "Run \(command) in Terminal, then retry.",
                actionTitle: "Copy Command"
            ) {
                toaster.copy(command, label: "Login command")
            }
        }
        return ListMessage.failure("Cannot read merge requests", description: error.localizedDescription) {
            Task { await gitLab.refresh() }
        }
    }

    private var emptyMessage: ListMessage {
        ListMessage(
            "No merge requests",
            systemImage: "arrow.triangle.pull",
            description: gitLab.filter.isActive
                ? "Nothing matches the filters. Clear them in the filter menu."
                : "Nothing matches \(gitLab.scope.title) · \(gitLab.query.state.title)."
        )
    }
}

#Preview {
    GitLabView()
        .previewEnvironment()
}
