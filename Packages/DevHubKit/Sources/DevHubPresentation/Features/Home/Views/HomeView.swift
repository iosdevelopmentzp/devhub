import SwiftUI
import DevHubDomain
import DevHubUI

struct HomeView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ActivityLog.self) private var activity
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(KeepAwakeStore.self) private var keepAwake
    @Environment(OpenPullRequestsStore.self) private var openPullRequests
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(AppActions.self) private var appActions
    @Environment(\.codeHostWords) private var words

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProjectCard(model: projectCard)

                TodayCard(items: todayItems) { appActions.open($0) }

                KeepAwakeCard(model: KeepAwakeCardMapper.model(isActive: keepAwake.isActive)) {
                    keepAwake.toggle()
                }

                ConfigIssuesSection()

                QuickActionsSection()

                ScriptsSection()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader("Recent") {
                        HStack(spacing: 10) {
                            Button("Show All (\(activity.events.count))") {
                                appActions.openNotifications()
                            }
                            .buttonStyle(LinkButtonStyle(.accent))
                            .disabled(activity.events.isEmpty)
                            Button("Clear") {
                                activity.clear()
                            }
                            .buttonStyle(LinkButtonStyle(.secondary))
                            .disabled(activity.events.isEmpty)
                        }
                    }
                    PanelCard {
                        if activity.events.isEmpty {
                            Text("Nothing yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 0) {
                                let rows = activityRows
                                ForEach(rows) { row in
                                    ActivityRow(model: row) {
                                        if let target = row.target {
                                            appActions.open(target)
                                        }
                                    }
                                    if row.id != rows.last?.id {
                                        Divider()
                                            .padding(.vertical, 6)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
        }
    }

    private var projectCard: ProjectCardModel {
        ProjectCardMapper.model(
            for: session.selectedProject,
            main: worktrees.mainWorktree,
            mainCheckoutPath: worktrees.mainCheckoutPath
        )
    }

    private var todayItems: [TodayItemModel] {
        TodayCardMapper.items(
            reviewCount: openPullRequests.reviewCount,
            openRequests: openPullRequests.requests,
            username: openPullRequests.username,
            worktrees: worktrees.worktrees,
            simulators: simulators.all,
            words: words
        )
    }

    private var activityRows: [ActivityRowModel] {
        activity.events.prefix(ActivityLog.homeLimit).map { ActivityRowMapper.model(for: $0, words: words) }
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
