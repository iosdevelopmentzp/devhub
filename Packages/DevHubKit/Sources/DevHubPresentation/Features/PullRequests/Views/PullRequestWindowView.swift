import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestWindowView: View {
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(CIWatchStore.self) private var ciWatch
    @Environment(PullRequestDetailStore.self) private var detailStore
    @Environment(PullRequestPeopleStore.self) private var people
    @Environment(AITextStore.self) private var aiText
    @Environment(CIAutoRerunStore.self) private var autoRerun
    @Environment(CIDiagnosticsStore.self) private var ciDiagnostics
    @Environment(AppActions.self) private var appActions
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SettingsStore.self) private var settings
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(\.codeHostWords) private var words

    let summary: PullRequestSummary

    @State private var isPickingLaunch = false
    @State private var selectedFileID: String?
    @State private var fileQuery = ""

    static let sidebarWidth: CGFloat = 280

    var body: some View {
        let details = details
        let detailActions = detailActions
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                PullRequestFileSidebar(model: sidebar(details), selectedID: selectedFileID, query: $fileQuery, actions: detailActions) { id in
                    selectedFileID = id
                    detailStore.revealFile(id, of: summary.id)
                }
                .frame(width: Self.sidebarWidth)
                Divider()
                VStack(spacing: 0) {
                    requestScroll
                    OperationsStrip(origin: .pullRequest(summary.id))
                }
            }
            .environment(\.diffScrollProxy, proxy)
            .onChange(of: detailStore.focus(of: summary.id)) { _, focus in
                guard let focus else { return }
                selectedFileID = focus.path
            }
        }
        .frame(minWidth: 1_000, minHeight: 560)
        .background(Theme.surface)
        .background {
            Button("Refresh", action: detailActions.refresh)
                .keyboardShortcut("r")
                .frame(width: 0, height: 0)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .task {
            await detailStore.load(summary.id)
            await people.loadIfNeeded()
        }
    }

    private var requestScroll: some View {
        ScrollView {
            PullRequestRow(
                model: PullRequestRowMapper.model(
                    for: current,
                    context: context,
                    local: PullRequestLocalStateMapper.state(for: current.sourceBranch, checkout: git, worktrees: worktrees),
                    isBusy: pullRequests.isBusy(summary.id),
                    isExpanded: true,
                    configActions: []
                ),
                details: details,
                isSelected: false,
                isNarrow: false,
                isPickingLaunch: isPickingLaunch,
                detailActions: detailActions,
                onToggle: {},
                onRequestLaunch: { isPickingLaunch = true },
                onCancelLaunch: { isPickingLaunch = false },
                onAction: { pullRequests.perform($0, on: summary.id) },
                onMerge: { pullRequests.merge(summary.id, kind: $0, squash: $1, removeSourceBranch: $2) },
                onLabel: nil
            )
            .padding(.vertical, 8)
        }
        .overlay(alignment: .bottom) {
            OperationsTray(origin: .pullRequest(summary.id), maxHeight: 320)
        }
    }

    private var detailActions: PullRequestDetailActions {
        PullRequestDetailActions.live(for: current, detailStore: detailStore, people: people, aiText: aiText, autoRerun: autoRerun, diagnostics: ciDiagnostics, pullRequests: pullRequests, settings: settings, appActions: appActions, configActions: configActions, openWindow: nil)
    }

    private var current: PullRequestSummary {
        if let listed = pullRequests.requests.first(where: { $0.id == summary.id }) {
            return listed
        }
        if let open = openPullRequests.requestsByBranch[summary.sourceBranch], open.id == summary.id {
            return open
        }
        return summary
    }

    private func sidebar(_ details: PullRequestDetailsModel) -> PullRequestFileSidebarModel? {
        guard case .loaded(let loaded) = details.content else { return nil }
        return PullRequestFileSidebarMapper.model(for: loaded, query: fileQuery)
    }

    private var context: PullRequestRowContext {
        PullRequestRowContext(
            username: pullRequests.username,
            reviewTeams: openPullRequests.reviewTeams,
            reviewQueue: openPullRequests.reviewQueue,
            scope: .all,
            seenAt: nil,
            now: .now,
            isMainCheckoutClean: git.isMainCheckoutClean,
            ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate),
            words: words,
            staleDays: git.gitSettings.pullRequests.staleDays,
            hiddenFiles: git.gitSettings.pullRequests.hiddenFiles,
            fileGroups: git.gitSettings.pullRequests.fileGroups,
            diffLayout: pullRequests.diffLayout,
            watchedIDs: openPullRequests.watchedIDs,
            onHoldJobs: ciWatch.onHoldJobNames,
            people: people.people,
            teams: people.teams,
            busyPeopleIDs: people.busyIDs,
            explanations: aiText.explanations,
            explainingIDs: aiText.explainingIDs,
            aiProvider: aiText.defaultProvider
        )
    }

    private var details: PullRequestDetailsModel {
        PullRequestDetailsMapper.model(
            summary: current,
            details: detailStore.details[summary.id],
            diffs: detailStore.diffs[summary.id],
            error: detailStore.errors[summary.id],
            review: detailStore.review(of: summary.id),
            context: context
        )
    }
}

#Preview {
    PullRequestWindowView(
        summary: PullRequestSummary(
            iid: 1842,
            title: "ABC-2324: Paid call payment",
            state: .opened,
            isDraft: false,
            webURL: URL(string: "https://gitlab.com/example/app/-/merge_requests/1842"),
            author: "alex",
            sourceBranch: "feature/ABC-2324-paid-call",
            targetBranch: "dev",
            hasConflicts: false,
            detailedStatus: .notApproved,
            commentCount: 4,
            updatedAt: nil,
            pipeline: PipelineInfo(status: .running, webURL: nil, updatedAt: nil),
            approvedBy: [],
            labels: ["feature"]
        )
    )
    .previewEnvironment()
    .frame(width: 1_120, height: 760)
}
