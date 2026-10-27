import SwiftUI
import DevHubDomain
import DevHubUI

struct HomeView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ActivityLog.self) private var activity
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(KeepAwakeStore.self) private var keepAwake

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProjectCard(model: projectCard)

                KeepAwakeCard(model: KeepAwakeCardMapper.model(isActive: keepAwake.isActive)) {
                    keepAwake.toggle()
                }

                ConfigIssuesSection()

                QuickActionsSection()

                ScriptsSection()

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader("Recent") {
                        Button("Clear") {
                            activity.clear()
                        }
                        .buttonStyle(LinkButtonStyle(.secondary))
                        .disabled(activity.events.isEmpty)
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
                                    ActivityRow(model: row)
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

    private var activityRows: [ActivityRowModel] {
        activity.events.map { ActivityRowMapper.model(for: $0) }
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
