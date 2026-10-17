import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(BuildStore.self) private var build
    @Environment(IdentityStore.self) private var identityStore
    @Environment(MockServerStore.self) private var mockServerStore
    @Environment(AppActions.self) private var appActions
    @Environment(ConfigActionsStore.self) private var configActions

    @State private var confirmingEraseID: Simulator.ID?
    @State private var isConfirmingBulkRemove = false
    @State private var editingIdentityID: Simulator.ID?
    @State private var messagingID: Simulator.ID?

    var body: some View {
        let sections = sections
        VStack(spacing: 0) {
            RunBar()
                .padding(14)
                .background(Theme.base)

            Divider()

            SimulatorsToolbar(isConfirmingBulkRemove: $isConfirmingBulkRemove)

            Divider()

            ListState(
                failure: unavailableMessage,
                isLoading: simulators.groups.isEmpty && simulators.isLoading,
                loadingTitle: "Reading simulators…",
                empty: nil,
                noResultsFor: sections.isEmpty ? session.searchText : nil
            ) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sections) { section in
                            ListSectionHeader(section.title, systemImage: section.systemImage, iconTint: .yellow, detail: section.detail, bottomPadding: 4)
                            ForEach(section.rows) { model in
                                row(model)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    .animation(.snappy(duration: 0.18), value: confirmingEraseID)
                    .animation(.snappy(duration: 0.18), value: editingIdentityID)
                    .animation(.snappy(duration: 0.18), value: messagingID)
                }
            }
        }
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: isConfirmingBulkRemove)
    }

    private var sections: [SimulatorSectionModel] {
        SimulatorSectionsMapper.sections(
            from: simulators.groups,
            matches: { simulator, runtime in session.matchesSearch(simulator.name, runtime, simulator.id) },
            row: rowModel
        )
    }

    private var unavailableMessage: ListMessage? {
        guard simulators.groups.isEmpty, simulators.isLoading == false else { return nil }
        return ListMessage(
            "No simulators",
            systemImage: "iphone.slash",
            description: simulators.error ?? "xcrun simctl returned no iOS simulators.",
            actionTitle: "Retry"
        ) {
            Task { await simulators.refresh() }
        }
    }

    private func rowModel(_ simulator: Simulator, runtime: String) -> SimulatorRowModel {
        SimulatorRowMapper.model(
            for: simulator,
            runtime: runtime,
            isTarget: build.isTarget(simulator.id),
            installedApps: simulators.installedAppCounts[simulator.id],
            identity: identityStore.identities[simulator.id],
            identitySettings: identityStore.settings(for: simulator.id),
            deviceIDAliases: identityStore.deviceIDAliases,
            mockState: mockServerStore.states[simulator.id],
            hasIdentityConfig: identityStore.config != nil,
            isUninstalling: simulators.isUninstalling(simulator.id),
            isApplying: identityStore.isApplying(simulator.id),
            buildIsRunning: build.isRunning,
            bundleID: session.selectedProject.bundleID,
            isConfirmingErase: confirmingEraseID == simulator.id,
            isEditingIdentity: editingIdentityID == simulator.id,
            isMessaging: messagingID == simulator.id,
            configActions: ConfigActionItemMapper.models(for: configActions.actions(for: .simulatorsRow), isRunning: configActions.isRunning)
        )
    }

    private func runConfigAction(_ id: String, for model: SimulatorRowModel) {
        configActions.request(
            id: id,
            item: ActionItemContext(simulatorUDID: model.id, simulatorName: model.name, rowID: model.id),
            slot: Placement.simulatorsRow.slot(for: model.id)
        )
    }

    private func row(_ model: SimulatorRowModel) -> some View {
        let id = model.id
        return SimulatorRow(
            model: model,
            onToggleIdentity: { editingIdentityID = editingIdentityID == id ? nil : id },
            onToggleMessaging: { messagingID = messagingID == id ? nil : id },
            onRemoveApps: { simulators.uninstallUserApps(id: id) },
            onTogglePower: { simulators.togglePower(id: id) },
            onOpenInSimulator: { simulators.openInSimulatorApp(id: id) },
            onToggleFavorite: { simulators.toggleFavorite(id: id) },
            onLaunchAndAttach: { launchInstalledApp(on: id, attachDebugger: true) },
            onUninstall: { simulators.uninstall(bundleID: session.selectedProject.bundleID, from: id) },
            onRequestErase: { confirmingEraseID = id },
            onCancelErase: { confirmingEraseID = nil },
            onConfirmErase: {
                confirmingEraseID = nil
                simulators.erase(id: id)
            },
            onConfigAction: { runConfigAction($0, for: model) }
        ) {
            panels(for: model)
        }
    }

    @ViewBuilder
    private func panels(for model: SimulatorRowModel) -> some View {
        if let pending = configActions.pending(in: Placement.simulatorsRow.slot(for: model.id)) {
            ConfigActionPrompt(pending: pending)
        }
        if model.isMessaging, let simulator = simulators.simulator(id: model.id) {
            MessagingPanel(simulator: simulator, onClose: { messagingID = nil })
        }
        if model.isEditingIdentity, let config = identityStore.config {
            identityPanel(id: model.id, config: config)
        }
    }

    private func identityPanel(id: Simulator.ID, config: DeviceIdentityConfig) -> some View {
        DeviceIdentityPanel(
            model: IdentityPanelMapper.model(
                for: identityStore.identities[id],
                config: config,
                settings: identityStore.settings(for: id),
                savedDeviceIDs: identityStore.savedDeviceIDs,
                aliases: identityStore.deviceIDAliases,
                isApplying: identityStore.isApplying(id),
                buildIsRunning: build.isRunning,
                cleanInstallIsOn: build.state.cleanInstall
            ),
            environment: Binding(
                get: { identityStore.settings(for: id).desiredEnvironment ?? "" },
                set: { identityStore.setDesiredEnvironment($0, for: id) }
            ),
            deviceID: Binding(
                get: { identityStore.settings(for: id).desiredDeviceID ?? "" },
                set: { identityStore.setDesiredDeviceID($0, for: id) }
            ),
            alias: Binding(
                get: { identityStore.alias(for: id) },
                set: { identityStore.setAlias($0, for: id) }
            ),
            onForget: { identityStore.forgetSavedDeviceID($0) },
            onRefresh: { await identityStore.refresh(id: id) },
            onLaunch: { launchInstalledApp(on: id, attachDebugger: $0) },
            onClose: { editingIdentityID = nil }
        )
    }

    private func launchInstalledApp(on id: Simulator.ID, attachDebugger: Bool) {
        guard let simulator = simulators.simulator(id: id) else { return }
        appActions.launchInstalledApp(on: simulator, attachDebugger: attachDebugger)
    }
}

#Preview {
    SimulatorsView()
        .previewEnvironment()
}
