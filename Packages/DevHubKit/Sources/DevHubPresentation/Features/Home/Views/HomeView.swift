import SwiftUI
import DevHubDomain
import DevHubUI

struct HomeView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ActivityLog.self) private var activity
    @Environment(WorktreesStore.self) private var worktrees
    @Environment(Toaster.self) private var toaster
    @Environment(BuildStore.self) private var build
    @Environment(AppActions.self) private var appActions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProjectCard(model: projectCard)

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader("Quick actions")
                    if quickActions.isEmpty {
                        Text("No actions match “\(session.searchText)”")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 8) {
                            ForEach(quickActions) { action in
                                QuickActionTile(action: action, isRunning: isRunning(action)) {
                                    run(action)
                                }
                            }
                        }
                    }
                }

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

    private var quickActions: [QuickAction] {
        QuickAction.all.filter { session.matchesSearch($0.title, $0.subtitle) }
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

    private func isRunning(_ action: QuickAction) -> Bool {
        (action.kind == .buildAndRun || action.kind == .runAndAttach) && build.isRunning
    }

    private func run(_ action: QuickAction) {
        let path = worktrees.mainCheckoutPath
        let branch = worktrees.mainWorktree?.branch
        switch action.kind {
        case .buildAndRun:
            appActions.buildAndRun()
        case .runAndAttach:
            appActions.runAndAttach()
        case .openXcode:
            appActions.openInXcode(path: path)
        case .openFinder:
            appActions.openInFinder(path: path)
        case .openTerminal:
            appActions.openTerminal(at: path)
        case .copyBranch:
            guard let branch else { return }
            toaster.copy(branch)
        case .openRepository:
            appActions.openRepository()
        case .newMergeRequest:
            guard let branch else { return }
            appActions.openNewMergeRequest(for: branch)
        }
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
