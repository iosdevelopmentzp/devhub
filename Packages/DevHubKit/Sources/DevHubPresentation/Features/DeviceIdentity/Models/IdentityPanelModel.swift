import Foundation
import DevHubDomain
import DevHubUI

struct IdentityPanelModel: Equatable {
    var lastLaunchText: String?
    var isInstalled: Bool
    var notInstalledText: String
    var environmentTag: TagModel
    var environmentNote: String?
    var apiHost: String?
    var deviceAlias: String?
    var deviceID: String?
    var deviceIDPlaceholder: String
    var userName: String?
    var userPublicID: String?
    var userPlaceholder: String
    var version: String
    var hooksTag: TagModel
    var launch: LaunchIdentityModel
    var cleanInstallNote: CleanInstallNoteModel
    var launchTitle: String
    var launchTint: Tint?
    var canLaunch: Bool

    static let preview = IdentityPanelModel(
        lastLaunchText: "last launch 5 min ago",
        isInstalled: true,
        notInstalledText: "com.example.app is not installed here. Build & Run first; the settings below apply on that launch.",
        environmentTag: TagModel("qa", tint: .teal),
        environmentNote: nil,
        apiHost: "api.qa.example.com",
        deviceAlias: "Sam QA",
        deviceID: "devhub-3f9a1c2e",
        deviceIDPlaceholder: "unknown, the app has not sent requests yet",
        userName: "Sam Test",
        userPublicID: "u_48213",
        userPlaceholder: "not logged in",
        version: "4.12.0 (812)",
        hooksTag: TagModel("debug hooks", tint: .green, systemImage: "checkmark"),
        launch: .preview,
        cleanInstallNote: .preview,
        launchTitle: "Launch",
        launchTint: nil,
        canLaunch: true
    )
}
