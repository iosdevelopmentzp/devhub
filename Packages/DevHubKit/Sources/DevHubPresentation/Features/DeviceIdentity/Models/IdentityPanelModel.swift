import Foundation
import DevHubDomain
import DevHubUI

struct IdentityPanelModel: Equatable {
    var lastLaunchText: String?
    var isInstalled: Bool
    var notInstalledText: String
    var profileTag: TagModel
    var profileNote: String?
    var host: String?
    var deviceAlias: String?
    var deviceID: String?
    var deviceIDPlaceholder: String
    var user: String?
    var userPlaceholder: String
    var version: String
    var hooksTag: TagModel
    var launch: LaunchIdentityModel
    var cleanInstallNote: CleanInstallNoteModel
    var launchTitle: String
    var launchTint: Tint?
    var canLaunch: Bool
    var canAttach: Bool

    static let preview = IdentityPanelMapper.model(context: .preview, bundleID: "com.example.app", buildIsRunning: false, cleanInstallIsOn: false)
}
