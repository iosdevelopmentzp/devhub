import Foundation
import DevHubDomain
import DevHubUI

struct CleanInstallNoteModel: Equatable {
    var icon: String
    var iconTint: Tint
    var text: String

    static let preview = CleanInstallNoteModel(
        icon: "info.circle",
        iconTint: .secondary,
        text: "Same device ID as now: the app is updated in place and the session stays."
    )
}
