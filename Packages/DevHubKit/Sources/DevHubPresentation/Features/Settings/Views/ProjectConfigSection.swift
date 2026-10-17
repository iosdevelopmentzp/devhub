import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectConfigSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster
    @Environment(ActivityLog.self) private var activity

    var body: some View {
        Section {
            LabeledContent("Layers") {
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(config.resolved.layers, id: \.self) { layer in
                        Text("\(layer.layer.rawValue): \(layer.directory.abbreviatingHome)\(layer.exists ? "" : " (none)")")
                            .font(.caption.monospaced())
                            .foregroundStyle(layer.exists ? .primary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .hintWhenTruncated(layer.directory)
                    }
                }
            }
            HStack {
                Button("Create .devhub Example", systemImage: "doc.badge.plus") {
                    createExample()
                }
                .fixedSize()
                .hint("Writes a .devhub folder with a project file, actions, scripts and a custom tab into the selected project. Nothing is written when the folder exists.")
                Button("Reveal .devhub Folder", systemImage: "folder") {
                    revealFolder()
                }
                .fixedSize()
            }
            .disabled(session.hasProject == false)
        } header: {
            Text("Project config")
        } footer: {
            Text("DevHub reads .devhub from the project, from ~/.devhub/projects/<folder name> and from ~/.devhub. The schema is in docs/extensions.md.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func createExample() {
        Task {
            do {
                let folder = try await config.createExample()
                activity.log("Created .devhub example", detail: folder, outcome: .success)
                toaster.show("Created \(folder.abbreviatingHome)")
            } catch {
                activity.log("Could not create the .devhub example", detail: error.localizedDescription, outcome: .failure)
                toaster.show(error.localizedDescription)
            }
        }
    }

    private func revealFolder() {
        Task {
            guard let folder = await config.existingFolder() else {
                toaster.show("No .devhub folder yet")
                return
            }
            appActions.openInFinder(path: folder)
        }
    }
}

#Preview {
    Form {
        ProjectConfigSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
