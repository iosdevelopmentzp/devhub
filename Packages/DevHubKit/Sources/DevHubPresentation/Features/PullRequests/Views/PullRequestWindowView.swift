import SwiftUI
import DevHubDomain
import DevHubUI

struct PullRequestWindowView: View {
    @Environment(PullRequestsStore.self) private var pullRequests
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(PullRequestDetailStore.self) private var detailStore
    @Environment(CIAutoRerunStore.self) private var autoRerun
    @Environment(AppActions.self) private var appActions
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SettingsStore.self) private var settings
    @Environment(ConfigActionsStore.self) private var configActions
    @Environment(\.codeHostWords) private var words

    let summary: PullRequestSummary

    @State private var isPickingLaunch = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                PullRequestRow(
                    model: PullRequestRowMapper.model(
                        for: summary,
                        context: context,
                        local: PullRequestLocalStateMapper.state(for: summary.sourceBranch, checkout: git, worktrees: worktrees),
                        isBusy: pullRequests.isBusy(summary.id),
                        isExpanded: true,
                        configActions: []
                    ),
                    details: details,
                    isSelected: false,
                    isNarrow: false,
                    isPickingLaunch: isPickingLaunch,
                    detailActions: PullRequestDetailActions.live(for: summary, detailStore: detailStore, autoRerun: autoRerun, pullRequests: pullRequests, appActions: appActions, configActions: configActions, openWindow: nil),
                    onToggle: {},
                    onRequestLaunch: { isPickingLaunch = true },
                    onCancelLaunch: { isPickingLaunch = false },
                    onAction: { pullRequests.perform($0, on: summary.id) },
                    onMerge: { pullRequests.merge(summary.id, kind: $0, squash: $1, removeSourceBranch: $2) },
                    onLabel: nil
                )
                .padding(.vertical, 8)
                OperationSlot(origin: .pullRequest(summary.id))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            .environment(\.diffScrollProxy, proxy)
            .onChange(of: detailStore.focus(of: summary.id)) { _, focus in
                guard let focus else { return }
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo(PullRequestFileRowModel.scrollID(focus.path), anchor: .top)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .background(Theme.surface)
        .task {
            await detailStore.load(summary.id)
        }
    }

    private var context: PullRequestRowContext {
        PullRequestRowContext(
            username: pullRequests.username,
            scope: .all,
            seenAt: nil,
            now: .now,
            isMainCheckoutClean: git.isMainCheckoutClean,
            ticket: git.gitSettings.ticket(fallbackURL: settings.values.ticketURLTemplate),
            words: words,
            staleDays: git.gitSettings.pullRequests.staleDays,
            hiddenFiles: git.gitSettings.pullRequests.hiddenFiles,
            watchedIDs: openPullRequests.watchedIDs
        )
    }

    private var details: PullRequestDetailsModel {
        PullRequestDetailsMapper.model(
            summary: summary,
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
    .frame(width: 820, height: 700)
}
