import SwiftUI
import DevHubDomain
import DevHubUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(Toaster.self) private var toaster
    @Environment(\.codeHostWords) private var words

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: launchAtLogin)
                if let error = settings.loginItemError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                Toggle("Show Dock icon", isOn: $settings.values.showDockIcon)
                Picker("Open DevHub from anywhere", selection: $settings.values.globalShortcut) {
                    ForEach(GlobalShortcut.allCases, id: \.self) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }
                .hint("A global key combination that opens the menu bar panel, or brings the pinned window to the front")
            }

            NotificationsSection()

            Section("Claude usage") {
                Toggle("Show usage strip at the top", isOn: $settings.values.showUsageStrip)
                Toggle("Show session usage in the menu bar", isOn: $settings.values.showUsageInMenuBar)
            }

            Section(words.requestsTitle) {
                Toggle("Show the number of \(words.requests) waiting for your review in the menu bar", isOn: $settings.values.showReviewCountInMenuBar)
                    .hint("Open \(words.requests) by other people, not drafts, that you have not approved. Checked every 5 minutes.")
            }

            Section {
                ForEach(session.projects) { project in
                    ProjectSettingsRow(
                        model: ProjectSettingsRowMapper.model(
                            for: project,
                            isSelected: project.id == session.selectedProjectID,
                            hasLaunchIdentity: config.config.launch?.identity != nil,
                            projectCount: session.projects.count
                        ),
                        scheme: field(\.scheme, of: project),
                        bundleID: field(\.bundleID, of: project),
                        onRedetect: { redetect(project) },
                        onRemove: { session.remove(id: project.id) }
                    )
                }
                Button("Add Project…", systemImage: "plus") {
                    addProject()
                }
            } header: {
                Text("Projects")
            } footer: {
                Text("Scheme and bundle ID are found in the project files. Change them here when the guess is wrong, or set them in .devhub/project.json.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProjectConfigSection()

            GlobalConfigSection()

            Section("Tools") {
                Picker("Editor", selection: $settings.values.editor) {
                    ForEach(["Xcode", "Cursor", "VS Code", "Zed"], id: \.self) { Text($0) }
                }
                Picker("Terminal", selection: $settings.values.terminal) {
                    ForEach(["Terminal", "iTerm2", "Ghostty", "Warp"], id: \.self) { Text($0) }
                }
            }

            Section {
                TextField("Ticket link", text: $settings.values.ticketURLTemplate, prompt: Text("https://tracker.example.com/browse/{key}"))
                    .font(.callout.monospaced())
            } header: {
                Text("Tickets")
            } footer: {
                Text("A ticket key such as ABC-2324 in a branch name or a \(words.request) title becomes a chip. With a link here, a click opens the ticket; {key} is replaced with the key. Without a link, a click copies the key. A project can set its own pattern and link with git.commitPrefix and git.ticketURL in .devhub/project.json.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Fetch when the Git tab opens", selection: $settings.values.autoFetchMinutes) {
                    Text("Never").tag(0)
                    ForEach([5, 15, 30, 60], id: \.self) { minutes in
                        Text("If older than \(minutes) min").tag(minutes)
                    }
                }
            } header: {
                Text("Git")
            } footer: {
                Text("DevHub runs Fetch once when you open the Git tab and the last fetch is older than this.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            DoctorSection()

            Section("About") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                LabeledContent("Features", value: "\(FeatureRegistry.all.count) registered")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { settings.launchesAtLogin },
            set: { settings.setLaunchAtLogin($0) }
        )
    }

    private func field(_ keyPath: WritableKeyPath<Project, String>, of project: Project) -> Binding<String> {
        Binding(
            get: { project[keyPath: keyPath] },
            set: { session.update(ProjectSettingsRowMapper.project(project, setting: keyPath, to: $0)) }
        )
    }

    private func redetect(_ project: Project) {
        guard let found = session.redetect(id: project.id) else { return }
        toaster.show(ProjectSettingsRowMapper.redetectMessage(for: found))
    }

    private func addProject() {
        guard let folder = FolderPicker.chooseFolder(
            directory: ProjectPath("~/Documents/Projects").url,
            prompt: "Add Project",
            message: "Choose the folder of an iOS project: the git checkout with the .xcodeproj or .xcworkspace"
        ) else { return }
        session.addProject(at: folder)
    }
}

#Preview {
    SettingsView()
        .previewEnvironment()
}
