import SwiftUI
import DevHubDomain
import DevHubUI

struct AISessionsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(AISessionsStore.self) private var claude
    @Environment(\.panelOpenCount) private var openCount

    var body: some View {
        VStack(spacing: 0) {
            AISessionsToolbar(count: visible.count)
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.surface)
        .task(id: openCount) {
            await claude.refresh()
        }
    }

    private var visible: [AISession] {
        claude.scoped.filter { session.matchesSearch($0.title, $0.cwd, $0.gitBranch ?? "", $0.lastPrompt ?? "") }
    }

    private var content: some View {
        ListState(
            failure: nil,
            isLoading: claude.hasLoaded == false,
            loadingTitle: "Reading Claude sessions…",
            empty: claude.scoped.isEmpty ? emptyMessage : nil,
            noResultsFor: visible.isEmpty ? session.searchText : nil
        ) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(AISessionSectionsMapper.sections(for: visible)) { section in
                        ListSectionHeader(section.title)
                        ForEach(section.rows) { row in
                            AISessionRow(model: row)
                            if row.id != section.rows.last?.id {
                                Divider()
                                    .padding(.leading, 56)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var emptyMessage: ListMessage {
        ListMessage(
            "No Claude sessions",
            systemImage: "bubble.left.and.text.bubble.right",
            description: claude.scope == .project
                ? "No sessions were started inside \(session.selectedProject.name). Switch to All to see every session."
                : "Claude Code has no saved sessions in ~/.claude/projects."
        )
    }
}

#Preview {
    AISessionsView()
        .previewEnvironment()
}
