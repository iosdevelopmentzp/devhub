import Foundation
import DevHubDomain
import DevHubUI

enum ScriptRowMapper {

    static func model(for script: ScriptAction, isRunning: Bool, editor: String) -> ScriptRowModel {
        ScriptRowModel(
            id: script.id,
            title: script.title,
            subtitle: script.subtitle,
            fileName: script.fileName,
            icon: script.systemImage,
            iconTint: .purple,
            lastRunText: script.lastRun.map { "ran \($0.relativeDescription)" } ?? "never run",
            isRunning: isRunning,
            editTitle: "Edit in \(editor)"
        )
    }
}
