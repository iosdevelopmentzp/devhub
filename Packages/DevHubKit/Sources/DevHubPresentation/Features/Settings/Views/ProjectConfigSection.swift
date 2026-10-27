import SwiftUI
import DevHubDomain
import DevHubUI

struct ProjectConfigSection: View {
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(AppActions.self) private var appActions
    @Environment(Toaster.self) private var toaster
    @Environment(ActivityLog.self) private var activity
    @Environment(GitStore.self) private var git
    @Environment(\.codeHostWords) private var words

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
            FlowLayout(spacing: 8) {
                Button("Create .devhub Starter", systemImage: "wand.and.stars") {
                    createStarter()
                }
                .fixedSize()
                .hint("Writes .devhub/project.json with what DevHub found: the name, the scheme, the bundle ID, the remote, the code host and the base branch. Edit it later. Nothing is written when the file exists.")
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

    private func createStarter() {
        Task {
            do {
                let file = try await config.createStarter(remote: git.remote, hostKind: words.kind, baseBranch: git.baseName)
                activity.log("Created .devhub/project.json", detail: file, outcome: .success)
                toaster.show("Created \(file.abbreviatingHome)")
                appActions.openFile(path: file)
            } catch {
                activity.log("Could not create .devhub/project.json", detail: error.localizedDescription, outcome: .failure)
                toaster.show(error.localizedDescription)
            }
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
