import Foundation
import DevHubDomain
import DevHubUI

struct ScriptRowModel: Identifiable, Equatable {
    let id: String
    var title: String
    var subtitle: String
    var fileName: String
    var icon: String
    var iconTint: Tint
    var lastRunText: String
    var tags: [TagModel]
    var blockedTag: TagModel?
    var chmodCommand: String
    var scriptPath: String?
    var isRunning: Bool
    var isRunnable: Bool
    var editTitle: String
    var isFavorite: Bool

    static let preview = ScriptRowModel(
        id: "script:reset-simulators",
        title: "Reset simulators",
        subtitle: "Erase every shut down simulator",
        fileName: "reset-simulators.sh",
        icon: "arrow.counterclockwise",
        iconTint: .purple,
        lastRunText: "never run",
        tags: [TagModel("project", tint: .indigo)],
        blockedTag: nil,
        chmodCommand: "chmod +x \"/repo/.devhub/scripts/reset-simulators.sh\"",
        scriptPath: "/repo/.devhub/scripts/reset-simulators.sh",
        isRunning: false,
        isRunnable: true,
        editTitle: "Edit in Xcode",
        isFavorite: true
    )
}
