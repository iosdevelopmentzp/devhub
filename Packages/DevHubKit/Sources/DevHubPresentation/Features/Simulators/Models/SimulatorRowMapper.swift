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
        isConfirmingErase: Bool,
        isEditingIdentity: Bool,
        isMessaging: Bool,
        configActions: [ConfigActionItemModel]
    ) -> SimulatorRowModel {
        let isTransitioning = isTransitioning(simulator.state)
        let isInstalled = identity?.isInstalled == true
        return SimulatorRowModel(
            id: simulator.id,
            name: simulator.name,
            runtimeTag: TagModel(runtime),
            kindIcon: kindIcon(simulator.kind),
            stateTint: stateTint(simulator.state),
            stateDotOpacity: simulator.state == .shutdown ? 0.35 : 1,
            stateText: stateText(simulator.state),
            detailText: isUninstalling ? "Removing apps…" : detailText(state: simulator.state, installedApps: installedApps ?? 0),
            status: SimulatorStatusLineMapper.model(status),
            isHighlighted: isTarget,
            targetTag: isTarget ? targetTag : nil,
            isFavorite: simulator.isFavorite,
            favoriteIcon: "star.fill",
            favoriteHint: "In favorites",
            favoriteMenuTitle: simulator.isFavorite ? "Remove from Favorites" : "Add to Favorites",
            identity: identity.flatMap { $0.isInstalled ? IdentityPanelMapper.summary(context: $0, mockState: mockState) : nil },
            hasIdentityConfig: identity != nil,
            isUninstalling: isUninstalling,
            powerHint: simulator.state == .booted ? "Shutdown" : "Boot",
            canBuildAndRun: buildIsRunning == false,
            canRemoveApps: isTransitioning == false && buildIsRunning == false,
            canTogglePower: isTransitioning == false,
            canStreamLogs: simulator.state == .booted,
            canLaunchAndAttach: buildIsRunning == false && isInstalled,
            uninstallTitle: "Uninstall \(bundleID)",
            canUninstallFromMenu: isTransitioning == false && isUninstalling == false,
            canShowAppData: simulator.state == .booted && bundleID.isEmpty == false,
            canErase: isTransitioning == false,
            copyUDIDLabel: "UDID \(simulator.id)",
            eraseConfirmation: "Erase all content and settings on \(simulator.name)? The simulator shuts down first.",
            isConfirmingErase: isConfirmingErase,
            isEditingIdentity: isEditingIdentity,
            isMessaging: isMessaging,
            pinsActions: isTarget || isUninstalling || isEditingIdentity || isMessaging,
            configActions: configActions
        )
    }

    static func kindIcon(_ kind: Simulator.Kind) -> String {
        kind == .pad ? "ipad" : "iphone"
    }

    private static let targetTag = TagModel(
        "target",
        tint: .blue,
        hint: "Build & Run and the run bar above use this simulator. Click a row to change it."
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

    private static func detailText(state: Simulator.State, installedApps: Int) -> String {
        let stateText = stateText(state)
        guard installedApps > 0 else { return stateText }
        return "\(stateText) · \(CountText.count(installedApps, "app")) installed"
    }
}
