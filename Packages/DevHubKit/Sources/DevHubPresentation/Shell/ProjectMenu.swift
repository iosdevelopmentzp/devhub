import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectMenu: View {
    @Environment(ProjectSession.self) private var session
    @Environment(WorktreesStore.self) private var worktrees

    @State private var isHovered = false

    var body: some View {
        Menu {
            ForEach(session.projects) { project in
                Button {
                    session.selectedProjectID = project.id
                } label: {
                    if project.id == session.selectedProjectID {
                        Label(project.name, systemImage: "checkmark")
                    } else {
                        Text(project.name)
                    }
                }
            }
            Divider()
            Button("Add Project…", systemImage: "plus") {
                guard let folder = FolderPicker.chooseFolder(
                    directory: ProjectPath("~/Documents/Projects").url,
                    prompt: "Add Project",
                    message: "Choose the folder of an iOS project: the git checkout with the .xcodeproj or .xcworkspace"
                ) else { return }
                session.addProject(at: folder)
            }
        } label: {
            HStack(spacing: 8) {
                IconTile(systemImage: "shippingbox.fill", tint: .indigo, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.selectedProject.name)
                        .font(.headline)
                    Text(branch)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hintWhenTruncated(branch)
                }
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(isHovered ? Theme.hover : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .onHover { isHovered = $0 }
        .frame(maxWidth: 340, alignment: .leading)
    }

    private var branch: String {
        worktrees.mainWorktree?.displayName ?? session.selectedProject.path
    }
}
