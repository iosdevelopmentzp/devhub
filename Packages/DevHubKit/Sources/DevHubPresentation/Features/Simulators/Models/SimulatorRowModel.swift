import Foundation
import DevHubDomain
import DevHubUI

struct SimulatorRowModel: Identifiable, Equatable {
    let id: Simulator.ID
    var name: String
    var runtimeTag: TagModel
    var kindIcon: String
    var stateTint: Tint
    var stateDotOpacity: Double
    var stateText: String
    var detailText: String
    var isHighlighted: Bool
    var targetTag: TagModel?
    var isFavorite: Bool
    var favoriteIcon: String
    var favoriteHint: String
    var favoriteMenuTitle: String
    var identity: IdentitySummaryModel?
    var hasIdentityConfig: Bool
    var isUninstalling: Bool
    var powerHint: String
    var canBuildAndRun: Bool
    var canRemoveApps: Bool
    var canTogglePower: Bool
    var canStreamLogs: Bool
    var canLaunchAndAttach: Bool
    var uninstallTitle: String
    var canUninstallFromMenu: Bool
    var canErase: Bool
    var copyUDIDLabel: String
    var eraseConfirmation: String
    var isConfirmingErase: Bool
    var isEditingIdentity: Bool
    var isMessaging: Bool
    var pinsActions: Bool

    func showsActions(isHovered: Bool) -> Bool {
        (isHovered || pinsActions) && isConfirmingErase == false
    }

    static let preview = SimulatorRowModel(
        id: "8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13",
        name: "iPhone 16 Pro",
        runtimeTag: TagModel("iOS 18.2"),
        kindIcon: "iphone",
        stateTint: .green,
        stateDotOpacity: 1,
        stateText: "Booted",
        detailText: "Booted · 3 apps installed",
        isHighlighted: true,
        targetTag: TagModel("target", tint: .blue, hint: "Build & Run and the run bar above use this simulator. Click a row to change it."),
        isFavorite: true,
        favoriteIcon: "star.fill",
        favoriteHint: "In favorites",
        favoriteMenuTitle: "Remove from Favorites",
        identity: .preview,
        hasIdentityConfig: true,
        isUninstalling: false,
        powerHint: "Shutdown",
        canBuildAndRun: true,
        canRemoveApps: true,
        canTogglePower: true,
        canStreamLogs: true,
        canLaunchAndAttach: true,
        uninstallTitle: "Uninstall com.example.app",
        canUninstallFromMenu: true,
        canErase: true,
        copyUDIDLabel: "UDID 8C2F6A1E-5B3D-4E7A-9F10-2D4C6B8A0E13",
        eraseConfirmation: "Erase all content and settings on iPhone 16 Pro? The simulator shuts down first.",
        isConfirmingErase: false,
        isEditingIdentity: false,
        isMessaging: false,
        pinsActions: true
    )
}
