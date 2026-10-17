import Foundation
import DevHubDomain
import DevHubUI

enum ScriptRowMapper {
    static func model(for action: ResolvedAction, isRunning: Bool, lastRun: Date?, editor: String) -> ScriptRowModel {
        let config = action.config
        let inputs = config.inputs ?? []
        let scriptPath = scriptPath(for: action)
        var tags: [TagModel] = []
        if inputs.isEmpty == false {
            tags.append(TagModel(inputs.count == 1 ? "1 input" : "\(inputs.count) inputs", tint: .gray))
        }
        tags.append(TagModel(action.origin.layer.rawValue, tint: action.origin.layer == .global ? .gray : .indigo, hint: layerHint(action.origin.layer)))
        return ScriptRowModel(
            id: action.id,
            title: config.title,
            subtitle: config.subtitle ?? "",
            fileName: URL(fileURLWithPath: action.origin.fileName).lastPathComponent,
            icon: config.icon ?? ConfigActionItemMapper.defaultSymbol,
            iconTint: config.tint == nil ? .purple : ConfigTintMapper.tint(config.tint),
            lastRunText: lastRun.map { "ran \($0.relativeDescription)" } ?? "never run",
            tags: tags,
            blockedTag: action.origin.isExecutable ? nil : TagModel("Run chmod +x", tint: .orange, systemImage: "lock", hint: "This file is not executable. Click to copy the command."),
            chmodCommand: "chmod +x \"\(scriptPath ?? action.origin.scriptPath)\"",
            scriptPath: scriptPath,
            isRunning: isRunning,
            isRunnable: action.origin.isExecutable,
            editTitle: "Edit in \(editor)"
        )
    }

    private static func scriptPath(for action: ResolvedAction) -> String? {
        guard case let .script(path) = action.config.run else { return nil }
        return path.hasPrefix("/") ? path : ProjectPath(action.origin.directory).expanded + "/" + path
    }

    private static func layerHint(_ layer: ConfigLayer) -> String {
        switch layer {
        case .project: "From the .devhub folder of the project"
        case .user: "From your own folder for this project in ~/.devhub/projects"
        case .global: "From ~/.devhub, shared by every project"
        }
    }
}
