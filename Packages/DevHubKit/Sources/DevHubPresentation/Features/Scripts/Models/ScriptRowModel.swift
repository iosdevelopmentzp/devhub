import Foundation
import DevHubDomain
import DevHubUI

struct ScriptRowModel: Identifiable, Equatable {
    let id: ScriptAction.ID
    var title: String
    var subtitle: String
    var fileName: String
    var icon: String
    var iconTint: Tint
    var lastRunText: String
    var isRunning: Bool
    var editTitle: String

    static let preview = ScriptRowModel(
        id: "reset-simulators",
        title: "Reset simulators",
        subtitle: "Erase every shutdown simulator",
        fileName: "reset-simulators.sh",
        icon: "arrow.counterclockwise",
        iconTint: .purple,
        lastRunText: "ran 3 hr. ago",
        isRunning: false,
        editTitle: "Edit in Xcode"
    )
}
