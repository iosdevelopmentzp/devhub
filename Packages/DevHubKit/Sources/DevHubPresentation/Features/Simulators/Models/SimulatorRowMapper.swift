import Foundation
import DevHubDomain
import DevHubUI

enum SimulatorRowMapper {

    static func model(
        for simulator: Simulator,
        runtime: String,
        isTarget: Bool,
        installedApps: Int?,
        status: SimulatorStatus?,
        identity: IdentityContext?,
        mockState: MockServerState?,
        isUninstalling: Bool,
        buildIsRunning: Bool,
        bundleID: String,
        simulatorApp: SimulatorApp,
        isConfirmingErase: Bool,
        isEditingIdentity: Bool,
        isMessaging: Bool,
        configActions: [ConfigActionItemModel]
    ) -> SimulatorRowModel {
        let isTransitioning = isTransitioning(simulator.state)
        let isInstalled = identity?.isInstalled == true
        let isPhysical = simulator.isPhysical
        let isConnected = simulator.state == .booted
        let stateText = isPhysical ? (isConnected ? "Connected" : "Not connected") : stateText(simulator.state)
        return SimulatorRowModel(
            id: simulator.id,
            name: simulator.name,
            runtimeTag: TagModel(runtime),
            deviceTag: isPhysical ? deviceTag : nil,
            kindIcon: kindIcon(simulator.kind),
            stateTint: stateTint(simulator.state),
            stateDotOpacity: simulator.state == .shutdown ? 0.35 : 1,
            stateText: stateText,
            detailText: isUninstalling ? "Removing apps…" : detailText(stateText: stateText, installedApps: isPhysical ? 0 : installedApps ?? 0),
            status: SimulatorStatusLineMapper.model(status),
            isHighlighted: isTarget,
            targetTag: isTarget ? (isPhysical ? deviceTargetTag : targetTag) : nil,
            isFavorite: simulator.isFavorite,
            favoriteIcon: "star.fill",
            favoriteHint: "In favorites",
            favoriteMenuTitle: simulator.isFavorite ? "Remove from Favorites" : "Add to Favorites",
            identity: identity.flatMap { $0.isInstalled ? IdentityPanelMapper.summary(context: $0, mockState: mockState) : nil },
            hasIdentityConfig: identity != nil,
            isUninstalling: isUninstalling,
            powerHint: simulator.state == .booted ? "Shutdown" : "Boot",
            canBuildAndRun: buildIsRunning == false && (isPhysical == false || isConnected),
            canRemoveApps: isPhysical == false && isTransitioning == false && buildIsRunning == false,
            canTogglePower: isPhysical == false && isTransitioning == false,
            canStreamLogs: isPhysical == false && simulator.state == .booted,
            canLaunchAndAttach: isPhysical == false && buildIsRunning == false && isInstalled,
            openAppTitle: "Open in \(appName(simulatorApp))",
            uninstallTitle: "Uninstall \(bundleID)",
            canUninstallFromMenu: isTransitioning == false && isUninstalling == false && (isPhysical == false || isConnected),
            canShowAppData: isPhysical == false && simulator.state == .booted && bundleID.isEmpty == false,
            canErase: isPhysical == false && isTransitioning == false,
            copyUDIDLabel: "UDID \(simulator.id)",
            eraseConfirmation: "Erase all content and settings on \(simulator.name)? The simulator shuts down first.",
            isConfirmingErase: isConfirmingErase,
            isEditingIdentity: isEditingIdentity,
            isMessaging: isMessaging,
            pinsActions: isTarget || isUninstalling || isEditingIdentity || isMessaging,
            showsSimulatorActions: isPhysical == false,
            configActions: configActions
        )
    }

    static func kindIcon(_ kind: Simulator.Kind) -> String {
        kind == .pad ? "ipad" : "iphone"
    }

    static func appName(_ app: SimulatorApp) -> String {
        switch app {
        case .simulator: "Simulator"
        case .deviceHub: "Device Hub"
        }
    }

    private static let targetTag = TagModel(
        "target",
        tint: .blue,
        hint: "Build & Run and the run bar above use this simulator. Click a row to change it."
    )

    private static let deviceTargetTag = TagModel(
        "target",
        tint: .blue,
        hint: "Build & Run and the run bar above use this device. Click a row to change it."
    )

    static let deviceTag = TagModel(
        "device",
        tint: .indigo,
        systemImage: "cable.connector",
        hint: "A physical device paired with this Mac. DevHub installs and launches the app with devicectl. Logs, mocks, Run & Attach, deep links and push are not available here yet."
    )

    private static func isTransitioning(_ state: Simulator.State) -> Bool {
        state == .booting || state == .shuttingDown
    }

    private static func stateTint(_ state: Simulator.State) -> Tint {
        switch state {
        case .booted: .green
        case .booting, .shuttingDown: .orange
        case .shutdown: .secondary
        }
    }

    private static func stateText(_ state: Simulator.State) -> String {
        switch state {
        case .booted: "Booted"
        case .booting: "Booting…"
        case .shuttingDown: "Shutting down…"
        case .shutdown: "Shutdown"
        }
    }

    private static func detailText(stateText: String, installedApps: Int) -> String {
        guard installedApps > 0 else { return stateText }
        return "\(stateText) · \(CountText.count(installedApps, "app")) installed"
    }
}
