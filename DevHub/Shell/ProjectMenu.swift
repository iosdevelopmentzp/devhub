import SwiftUI

struct ProjectMenu: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config

    private enum Choice: Hashable {
        case project(Project)
        case add
        case none
    }

    private var items: [Choice] {
        session.projects.map(Choice.project) + [.add]
    }

    private var selection: Binding<Choice> {
        Binding(
            get: { session.project.map(Choice.project) ?? .none },
            set: { choice in
                switch choice {
                case let .project(project): session.select(project)
                case .add: session.addUsingPicker()
                case .none: break
                }
            }
        )
    }

    var body: some View {
        SearchablePicker(title: "Project", selection: selection, items: items, label: label, detail: detail)
            .trigger { _ in AnyView(triggerLabel) }
            .hint("Switch project")
    }

    private var triggerLabel: some View {
        HStack(spacing: 10) {
            IconTile(systemImage: "cube", tint: .indigo, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(session.project.map { projectName($0) } ?? "No project")
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 3) {
                    Text(session.project == nil ? "Add a project" : session.branch ?? "No branch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func projectName(_ project: Project) -> String {
        session.project == project ? config.effective?.name ?? project.name : project.name
    }

    private func label(_ choice: Choice) -> String {
        switch choice {
        case let .project(project): projectName(project)
        case .add: "Add project…"
        case .none: "No project"
        }
    }

    private func detail(_ choice: Choice) -> String? {
        guard case let .project(project) = choice else { return nil }
        return URL(fileURLWithPath: project.path).deletingLastPathComponent().lastPathComponent
    }
}

#Preview {
    ProjectMenu()
        .padding()
        .previewEnvironment()
}
