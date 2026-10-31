import SwiftUI
import DevHubDomain
import DevHubUI

struct RunBar: View {
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(SimulatorStatusStore.self) private var statuses
    @Environment(IdentityStore.self) private var identityStore
    @Environment(MockServerStore.self) private var mockServerStore
    @Environment(AppActions.self) private var appActions

    @State private var editsSchemes = false

    var body: some View {
        let model = model
        PanelCard {
            VStack(alignment: .leading, spacing: 10) {
                options(model)
                if editsSchemes, build.isCommandProject == false {
                    SchemeEditor(
                        model: schemeEditorModel,
                        onAdd: { build.addScheme($0) },
                        onRemove: { build.removeScheme($0) },
                        onDone: { editsSchemes = false }
                    )
                    .task { await build.loadSchemeSuggestions() }
                }
                if let profile = LaunchProfileMapper.model(profiles: build.profiles, selected: build.profile) {
                    LaunchProfilePicker(model: profile) { build.setProfile($0) }
                }

                HStack(spacing: 12) {
                    targetColumn(model)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    runButtons(model)
                        .fixedSize()
                }

                ConfigActionBar(placement: .simulatorsRunBar, item: .none)

                if let target = model.target, let launch = target.launch {
                    Divider()
                    LaunchIdentityControls(
                        model: launch,
                        deviceID: deviceIDBinding(for: target.id),
                        alias: aliasBinding(for: target.id),
                        onForget: { identityStore.forgetSavedDeviceID($0) },
                        newID: { identityStore.newIdentity() }
                    )
                    if let note = target.cleanInstallNote {
                        CleanInstallNote(model: note)
                    }
                }

                if let progress = model.progress {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(value: progress.value)
                        Text(progress.step)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                if let outcome = model.outcome {
                    outcomeRow(outcome, canShowLog: model.canShowLog)
                }
                if build.issues.isEmpty == false {
                    BuildIssuesList(
                        title: BuildIssuesMapper.title(for: build.issues),
                        rows: BuildIssuesMapper.rows(for: build.issues),
                        onOpen: { row in
                            guard let path = row.path else { return }
                            appActions.openFile(path: path, line: row.line)
                        },
                        onFix: build.issues.contains { $0.severity == .error } ? { appActions.fixBuild(with: $0) } : nil
                    )
                }
            }
        }
        .animation(.snappy(duration: 0.2), value: build.isRunning)
    }

    private var model: RunBarModel {
        let target = build.target
        return RunBarMapper.model(
            state: build.state,
            target: target,
            runtime: target.flatMap { simulators.runtime(for: $0.id) },
            identity: target.flatMap { identityStore.context(for: $0.id) },
            mockState: target.flatMap { mockServerStore.states[$0.id] },
            hasLog: build.hasLog,
            isLoadingSimulators: simulators.isLoading
        )
    }

    private var schemeEditorModel: SchemeEditorModel {
        SchemeEditorMapper.model(
            manual: build.manualSchemes,
            suggestions: build.newSchemeSuggestions,
            isLoaded: build.schemeSuggestions != nil,
            isLoading: build.isLoadingSchemeSuggestions
        )
    }

    private func options(_ model: RunBarModel) -> some View {
        HStack(spacing: 8) {
            if let commands = build.commandsSummary {
                Label(commands, systemImage: "terminal")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .hint("This project builds and runs with build.command and run.command: \(commands). A line @devhub {\"app\": \"<path>\"} makes DevHub install and launch that app.")
            } else {
                xcodePickers
            }
            BuildSourceMenu()
            Toggle("Fast", isOn: Binding(get: { build.state.incremental }, set: { build.setIncremental($0) }))
                .toggleStyle(.checkbox)
                .hint("Incremental build: skip xcodebuild clean and reuse DerivedData")
                .disabled(build.isCommandProject)
            Toggle("Clean install", isOn: Binding(get: { build.state.cleanInstall }, set: { build.setCleanInstall($0) }))
                .toggleStyle(.checkbox)
                .hint("Cold install: delete the app and reset the simulator keychain before installing")
            Spacer()
            IconButton(systemImage: "arrow.clockwise", help: "Refresh simulators") {
                Task { await simulators.refresh() }
            }
            .disabled(model.canRefreshSimulators == false)
        }
        .controlSize(.small)
    }

    private var xcodePickers: some View {
        HStack(spacing: 8) {
            Picker("Scheme", selection: Binding(get: { build.state.scheme }, set: { build.setScheme($0) })) {
                ForEach(build.schemeOptions, id: \.self) { scheme in
                    Text(scheme).tag(scheme)
                }
            }
            .labelsHidden()
            .frame(width: 140)
            IconButton(systemImage: "plus.rectangle.on.rectangle", help: "Add or remove schemes and targets of the scheme list") {
                editsSchemes.toggle()
            }
            Picker("Configuration", selection: Binding(get: { build.state.configuration }, set: { build.setConfiguration($0) })) {
                ForEach(build.configurationOptions, id: \.self) { configuration in
                    Text(configuration).tag(configuration)
                }
            }
            .labelsHidden()
            .frame(width: 90)
        }
    }

    private func targetColumn(_ model: RunBarModel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.targetLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            if let target = model.target {
                HStack(spacing: 6) {
                    Image(systemName: target.icon)
                        .foregroundStyle(.secondary)
                    Text(target.name)
                        .font(.callout.weight(.medium))
                    if let runtimeTag = target.runtimeTag {
                        ModelTag(model: runtimeTag)
                    }
                }
                if let status = SimulatorStatusLineMapper.model(statuses.statuses[target.id]) {
                    SimulatorStatusLine(model: status)
                }
                if let identity = target.identity {
                    IdentitySummary(model: identity)
                } else if let missing = target.identityMissingText {
                    Text(missing)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(model.noTargetText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runButtons(_ model: RunBarModel) -> some View {
        HStack(spacing: 8) {
            if model.isRunning {
                Button("Cancel", role: .cancel) {
                    build.cancel()
                }
            } else {
                Button {
                    appActions.buildOnly()
                } label: {
                    Label("Build", systemImage: "hammer.fill")
                }
                .keyboardShortcut("b")
                .hint(build.isCommandProject ? "Run build.command only, without run.command and without a launch (⌘B)" : "Build only: compile without an install or a launch (⌘B). The app path is in the build log")
                .disabled(model.canRun == false)
                Button {
                    appActions.runAndAttach()
                } label: {
                    Label("Run & Attach", systemImage: "ladybug.fill")
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .hint(build.isCommandProject ? "Run & Attach needs an Xcode project. This project builds with its commands." : "Build, launch frozen with --wait-for-debugger and attach Xcode (⇧⌘R). Xcode's console stays empty for an attached process.")
                .disabled(model.canRun == false || build.isCommandProject)
                Button {
                    appActions.buildAndRun()
                } label: {
                    Label("Build & Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("r")
                .hint("Build and launch on the target simulator (⌘R)")
                .disabled(model.canRun == false)
            }
        }
    }

    private func outcomeRow(_ outcome: RunBarModel.Outcome, canShowLog: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            StatusDot(color: outcome.tint.color)
            Text(outcome.text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer()
            Button("Show log", systemImage: "doc.text") {
                build.showLog()
            }
            .buttonStyle(LinkButtonStyle(.secondary))
            .disabled(canShowLog == false)
        }
    }

    private func aliasBinding(for id: Simulator.ID) -> Binding<String> {
        Binding(
            get: { identityStore.alias(for: id) },
            set: { identityStore.setAlias($0, for: id) }
        )
    }

    private func deviceIDBinding(for id: Simulator.ID) -> Binding<String> {
        Binding(
            get: { identityStore.settings(for: id).desiredIdentity ?? "" },
            set: { identityStore.setDesiredDeviceID($0, for: id) }
        )
    }
}

#Preview {
    RunBar()
        .padding()
        .previewEnvironment()
}
