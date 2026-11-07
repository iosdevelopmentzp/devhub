import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorsView: View {
    @Environment(ProjectSession.self) private var session
    @Environment(SimulatorsStore.self) private var simulators
    @Environment(BuildStore.self) private var build
    @Environment(SimulatorStatusStore.self) private var statuses
    @Environment(IdentityStore.self) private var identityStore
    @Environment(MockServerStore.self) private var mockServerStore
    @Environment(AppActions.self) private var appActions
    @Environment(ConfigActionsStore.self) private var configActions

    @State private var confirmingEraseID: Simulator.ID?
    @State private var isConfirmingBulkRemove = false
    @State private var editingIdentityID: Simulator.ID?
    @State private var messagingID: Simulator.ID?
    @State private var qaID: Simulator.ID?
    @State private var appDataID: Simulator.ID?
    @State private var dropTargetID: Simulator.ID?

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
                            let isFavorites = section.id == SimulatorSectionsMapper.favoritesID
                            ListSectionHeader(section.title, systemImage: section.systemImage, iconTint: .yellow, detail: section.detail, bottomPadding: 4)
                                .hint(isFavorites ? SimulatorSectionsMapper.favoritesHint : nil)
                            ForEach(section.rows) { model in
                                if isFavorites {
                                    favoriteRow(model)
                                } else {
                                    row(model)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    .animation(.snappy(duration: 0.18), value: confirmingEraseID)
                    .animation(.snappy(duration: 0.18), value: editingIdentityID)
                    .animation(.snappy(duration: 0.18), value: messagingID)
                    .animation(.snappy(duration: 0.18), value: qaID)
                    .animation(.snappy(duration: 0.18), value: appDataID)
                }
            }
        }
        .background(Theme.surface)
        .animation(.snappy(duration: 0.18), value: isConfirmingBulkRemove)
        .task(id: build.target?.id) {
            statuses.loadMissing()
        }
    }

    private var sections: [SimulatorSectionModel] {
        SimulatorSectionsMapper.sections(
            from: simulators.groups,
            favoriteOrder: simulators.favoriteOrder,
            matches: { simulator, runtime in session.matchesSearch(simulator.name, runtime, simulator.id) },
            row: rowModel
        )
    }

    private var unavailableMessage: ListMessage? {
        guard simulators.groups.isEmpty, simulators.isLoading == false else { return nil }
        return ListMessage(
            "No simulators or devices",
            systemImage: "iphone.slash",
            description: simulators.error ?? "xcrun simctl returned no iOS simulators, and devicectl lists no paired iPhone or iPad.",
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
            status: statuses.statuses[simulator.id],
            identity: identityStore.context(for: simulator.id),
            mockState: mockServerStore.states[simulator.id],
            isUninstalling: simulators.isUninstalling(simulator.id),
            buildIsRunning: build.isRunning,
            bundleID: identityStore.bundleID(for: simulator.id),
            simulatorApp: simulators.app,
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

    private func favoriteRow(_ model: SimulatorRowModel) -> some View {
        row(model)
            .overlay {
                if dropTargetID == model.id {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                        .padding(.horizontal, 6)
                        .allowsHitTesting(false)
                }
            }
            .draggable(model.id)
            .dropDestination(for: String.self) { ids, _ in
                dropTargetID = nil
                guard let id = ids.first else { return false }
                simulators.moveFavorite(id: id, onto: model.id)
                return true
            } isTargeted: { isTargeted in
                if isTargeted {
                    dropTargetID = model.id
                } else if dropTargetID == model.id {
                    dropTargetID = nil
                }
            }
    }

    private func row(_ model: SimulatorRowModel) -> some View {
        let id = model.id
        return SimulatorRow(
            model: model,
            onToggleIdentity: { editingIdentityID = editingIdentityID == id ? nil : id },
            onToggleMessaging: { messagingID = messagingID == id ? nil : id },
            onToggleQA: { qaID = qaID == id ? nil : id },
            onToggleAppData: { appDataID = appDataID == id ? nil : id },
            onRemoveApps: { simulators.uninstallUserApps(id: id) },
            onTogglePower: { simulators.togglePower(id: id) },
            onOpenInSimulator: { simulators.openInSimulatorApp(id: id) },
            onToggleFavorite: { simulators.toggleFavorite(id: id) },
            onLaunchAndAttach: { launchInstalledApp(on: id, attachDebugger: true) },
            onUninstall: { simulators.uninstall(bundleID: identityStore.bundleID(for: id), from: id) },
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
        if qaID == model.id, let simulator = simulators.simulator(id: model.id) {
            SimulatorQAPanel(simulator: simulator, bundleID: identityStore.bundleID(for: model.id), onClose: { qaID = nil })
        }
        if appDataID == model.id, let simulator = simulators.simulator(id: model.id) {
            AppDataPanel(simulator: simulator, bundleID: identityStore.bundleID(for: model.id), onClose: { appDataID = nil })
        }
        if model.isEditingIdentity, let context = identityStore.context(for: model.id) {
            identityPanel(id: model.id, context: context)
        }
    }

    private func identityPanel(id: Simulator.ID, context: IdentityContext) -> some View {
        DeviceIdentityPanel(
            model: IdentityPanelMapper.model(context: context, bundleID: identityStore.bundleID(for: id), buildIsRunning: build.isRunning, cleanInstallIsOn: build.state.cleanInstall),
            deviceID: Binding(
                get: { identityStore.settings(for: id).desiredIdentity ?? "" },
                set: { identityStore.setDesiredDeviceID($0, for: id) }
            ),
            alias: Binding(
                get: { identityStore.alias(for: id) },
                set: { identityStore.setAlias($0, for: id) }
            ),
            onForget: { identityStore.forgetSavedDeviceID($0) },
            newID: { identityStore.newIdentity() },
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
