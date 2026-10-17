import SwiftUI

struct HomeView: View {
    @Environment(HomeStore.self) private var store
    @Environment(ProjectSession.self) private var session

    var body: some View {
        Group {
            if session.hasProject {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ConfigIssuesSection()
                        ProjectCard()
                        QuickActionsSection()
                        ScriptsSection()
                        RecentActivitySection()
                    }
                    .padding(14)
                }
            } else {
                NoProjectState()
            }
        }
        .background(Theme.base)
        .task { await store.refresh() }
    }
}

#Preview {
    HomeView()
        .previewEnvironment()
}
