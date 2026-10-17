import SwiftUI
import DevHubDomain
import DevHubUI

struct MergeRequestWindowView: View {
    @Environment(GitLabStore.self) private var gitLab
    @Environment(MergeRequestDetailStore.self) private var detailStore
    @Environment(AppActions.self) private var appActions
    @Environment(GitStore.self) private var git
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(SettingsStore.self) private var settings

    let summary: MergeRequestSummary

    @State private var isPickingLaunch = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                MergeRequestRow(
                    model: MergeRequestRowMapper.model(
                        for: summary,
                        context: MergeRequestRowContext(username: gitLab.username, scope: .all, seenAt: nil, now: .now, isMainCheckoutClean: git.isMainCheckoutClean, ticketURLTemplate: settings.values.ticketURLTemplate),
                        local: MergeRequestLocalStateMapper.state(for: summary.sourceBranch, checkout: git, worktrees: worktrees),
                        isBusy: gitLab.isBusy(summary.id),
                        isExpanded: true
                    ),
                    details: details,
                    isSelected: false,
                    isNarrow: false,
                    isPickingLaunch: isPickingLaunch,
                    detailActions: MergeRequestDetailActions.live(for: summary, detailStore: detailStore, gitLab: gitLab, appActions: appActions, openWindow: nil),
                    onToggle: {},
                    onRequestLaunch: { isPickingLaunch = true },
                    onCancelLaunch: { isPickingLaunch = false },
                    onAction: { gitLab.perform($0, on: summary.id) },
                    onMerge: { gitLab.merge(summary.id, kind: $0, squash: $1, removeSourceBranch: $2) }
                )
                .padding(.vertical, 8)
            }
            .environment(\.diffScrollProxy, proxy)
            .onChange(of: detailStore.focus(of: summary.id)) { _, focus in
                guard let focus else { return }
                withAnimation(.snappy(duration: 0.25)) {
                    proxy.scrollTo(MergeRequestFileRowModel.scrollID(focus.path), anchor: .top)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 400)
        .background(Theme.surface)
        .task {
            await detailStore.load(summary.id)
        }
    }

    private var details: MergeRequestDetailsModel {
        MergeRequestDetailsMapper.model(
            summary: summary,
            details: detailStore.details[summary.id],
            diffs: detailStore.diffs[summary.id],
            error: detailStore.errors[summary.id],
            review: detailStore.review(of: summary.id)
        )
    }
}

#Preview {
    MergeRequestWindowView(
        summary: MergeRequestSummary(
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
