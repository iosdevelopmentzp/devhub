import SwiftUI
import DevHubDomain
import DevHubUI

struct NoProjectState: View {
    @Environment(ProjectSession.self) private var session

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("No project yet")
                .font(.headline)
            Text("Add the folder of a repository. DevHub detects the Xcode container, the schemes and the git branch.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)
            Button("Add Project…") {
                guard let folder = FolderPicker.chooseFolder(
                    directory: ProjectPath("~").url,
                    prompt: "Add Project",
                    message: "Choose the folder of a repository: the git checkout, with an .xcodeproj or .xcworkspace if it has one"
                ) else { return }
                session.addProject(at: folder)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NoProjectState()
        .previewEnvironment()
}
