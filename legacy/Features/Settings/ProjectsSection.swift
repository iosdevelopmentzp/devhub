import SwiftUI

struct ProjectsSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(SettingsTabStore.self) private var store

    private var projects: [Project] {
        session.projects.filter { session.matchesSearch($0.name, $0.path) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader("Projects") {
                Button("Add project…") { session.addUsingPicker() }
            }
            PanelCard {
                VStack(alignment: .leading, spacing: 0) {
                    projectList
                    createExampleButton
                }
            }
        }
    }

    @ViewBuilder
    private var projectList: some View {
        if projects.isEmpty {
            Text(session.projects.isEmpty ? "No projects yet. Add the folder of a repository." : "No project matches the search.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 0) {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                    if project.id != projects.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var createExampleButton: some View {
        if let project = session.project {
            HStack {
                Spacer()
                Button("Create .devhub example for \(project.name)") { store.createExample(for: project) }
                    .controlSize(.small)
                    .hint("Copies the example config into <project>/.devhub. It refuses when the folder exists.")
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    ProjectsSection()
        .padding()
        .previewEnvironment()
}
