import SwiftUI
import DevHubDomain
import DevHubUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(ProjectSession.self) private var session
    @Environment(ConfigStore.self) private var config
    @Environment(XcodeSelectionStore.self) private var xcodes
    @Environment(PullRequestReviewMemory.self) private var reviews
    @Environment(FlakyTestLedger.self) private var flakyTests
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
                Picker("Window", selection: $settings.values.windowMode) {
                    ForEach(WindowMode.allCases, id: \.self) { mode in
                        Text(WindowModeText.title(for: mode)).tag(mode)
                    }
                }
                .hint(WindowModeText.hint(for: settings.values.windowMode))
                Toggle("Show Dock icon", isOn: $settings.values.showDockIcon)
                    .disabled(settings.values.windowMode == .window)
                    .hint(settings.values.windowMode == .window ? "A normal window always has a Dock icon" : nil)
                Picker("Open DevHub from anywhere", selection: $settings.values.globalShortcut) {
                    ForEach(GlobalShortcut.allCases, id: \.self) { shortcut in
                        Text(shortcut.title).tag(shortcut)
                    }
                }
                .hint(WindowModeText.shortcutHint(for: settings.values.windowMode))
            }

            NotificationsSection()

            Section("AI usage") {
                Picker("Show usage for", selection: $settings.values.usageProviders) {
                    ForEach(UsageProviders.allCases, id: \.self) { providers in
                        Text(UsageProvidersText.title(for: providers)).tag(providers)
                    }
                }
                .hint("Which plan limits the usage strip and the menu bar show. DevHub reads only the chosen providers. Off: DevHub reads no token and calls neither api.anthropic.com nor api.github.com.")
                Toggle("Show usage strip at the top", isOn: $settings.values.showUsageStrip)
                Toggle("Show session usage in the menu bar", isOn: $settings.values.showUsageInMenuBar)
                    .hint("The used percent of the first limit of the first chosen provider, next to the menu bar icon")
                Picker("Write with AI and Explain use", selection: $settings.values.aiTextProvider) {
                    ForEach(AIProvider.allCases, id: \.self) { provider in
                        Text(AISessionRowMapper.toolTitle(for: provider)).tag(provider)
                    }
                }
                .hint("The tool for commit messages, new requests and Explain. DevHub runs it once with -p and reads its answer. The arrow next to each button picks the other tool for one run. ai.textCommands in .devhub/project.json changes the command.")
            }

            Section(words.requestsTitle) {
                Toggle("Show the number of \(words.requests) waiting for your review in the menu bar", isOn: $settings.values.showReviewCountInMenuBar)
                    .hint("Open \(words.requests) by other people, not drafts, that you have not approved. Checked every 5 minutes.")
                Toggle("Remember what I reviewed", isOn: remembersReviews)
                    .hint("When you approve, comment, ask for changes or mark every file as viewed, DevHub saves the diff of each file on this Mac. The details then show the files that changed since, and Viewed marks stay until a file changes. Off removes everything DevHub saved.")
                LabeledContent {
                    Button("Forget Flaky Tests") {
                        flakyTests.forget()
                        toaster.show("Flaky tests forgotten")
                    }
                    .disabled(flakyTests.records.isEmpty)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(FlakyLedgerText.title(count: flakyTests.records.count))
                        Text("A test that failed in a CircleCI workflow and passed when the same commit ran again. DevHub counts it per project and marks it \"flaky (DevHub)\" next to the CircleCI Insights list.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
                        developerDir: xcodeChoice(of: project),
                        xcodeOptions: XcodeOptionMapper.options(
                            installations: xcodes.installations,
                            systemDeveloperDir: xcodes.systemDeveloperDir,
                            configDeveloperDir: project.id == session.selectedProjectID ? xcodes.configDeveloperDir : nil,
                            choice: project.developerDir
                        ),
                        xcodeSummary: project.id == session.selectedProjectID ? XcodeOptionMapper.summary(effective: xcodes.effectiveDeveloperDir, systemDeveloperDir: xcodes.systemDeveloperDir, installations: xcodes.installations) : nil,
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

            DiskCleanupSection()

            Section("About") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                LabeledContent("Features", value: "\(FeatureRegistry.all.count) registered")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .task {
            await xcodes.refresh()
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { settings.launchesAtLogin },
            set: { settings.setLaunchAtLogin($0) }
        )
    }

    private var remembersReviews: Binding<Bool> {
        Binding(
            get: { settings.values.remembersReviews },
            set: { isOn in
                settings.values.remembersReviews = isOn
                guard isOn == false else { return }
                reviews.forgetAll()
            }
        )
    }

    private func field(_ keyPath: WritableKeyPath<Project, String>, of project: Project) -> Binding<String> {
        Binding(
            get: { project[keyPath: keyPath] },
            set: { session.update(ProjectSettingsRowMapper.project(project, setting: keyPath, to: $0)) }
        )
    }

    private func xcodeChoice(of project: Project) -> Binding<String> {
        Binding(
            get: { project.developerDir ?? "" },
            set: { xcodes.choose($0, for: project) }
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
