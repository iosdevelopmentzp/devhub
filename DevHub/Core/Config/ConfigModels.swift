import Foundation

nonisolated enum ConfigLayer: String, Hashable, Sendable {
    case user
    case project
    case global

    var rank: Int {
        switch self {
        case .user: 0
        case .project: 1
        case .global: 2
        }
    }

    var title: String {
        switch self {
        case .user: "user"
        case .project: "project"
        case .global: "global"
        }
    }
}

nonisolated struct ConfigLayerInfo: Hashable, Sendable {
    let layer: ConfigLayer
    let directory: String
    var exists: Bool
}

nonisolated struct ActionOrigin: Hashable, Sendable {
    let layer: ConfigLayer
    let directory: String
    let fileName: String
    let isHeaderScript: Bool
    let isExecutable: Bool

    var scriptPath: String {
        directory + "/" + fileName
    }
}

nonisolated struct ResolvedAction: Identifiable, Hashable, Sendable {
    let config: ActionConfig
    let origin: ActionOrigin

    var id: String { config.id }
}

nonisolated struct ConfigIssue: Identifiable, Hashable, Sendable {
    let layer: ConfigLayer
    let fileName: String
    let message: String

    var id: String { "\(layer.rawValue)/\(fileName)/\(message)" }
}

nonisolated struct ResolvedConfig: Sendable {
    var project: ProjectConfig
    var actions: [ResolvedAction]
    var tabs: [TabConfig]
    var issues: [ConfigIssue]
    var layers: [ConfigLayerInfo]

    static let empty = ResolvedConfig(project: .empty, actions: [], tabs: [], issues: [], layers: [])

    func action(id: String) -> ResolvedAction? {
        actions.first { $0.id == id }
    }
}

nonisolated struct ConfigFile: Sendable {
    let name: String
    let text: String
}

nonisolated struct ScriptFile: Sendable {
    let name: String
    let head: String
    let isExecutable: Bool
}

nonisolated struct ConfigLayerFiles: Sendable {
    let layer: ConfigLayer
    let directory: String
    var exists: Bool
    var projectFile: ConfigFile?
    var actionFiles: [ConfigFile] = []
    var scriptFiles: [ScriptFile] = []
    var tabFiles: [ConfigFile] = []
    var readIssues: [ConfigIssue] = []
}

nonisolated enum ConfigPaths {
    static let folderName = ".devhub"

    static func layers(projectPath: String, home: String) -> [ConfigLayerInfo] {
        let name = URL(fileURLWithPath: projectPath).lastPathComponent
        return [
            ConfigLayerInfo(layer: .global, directory: home + "/" + folderName, exists: false),
            ConfigLayerInfo(layer: .project, directory: projectPath + "/" + folderName, exists: false),
            ConfigLayerInfo(layer: .user, directory: home + "/" + folderName + "/projects/" + name, exists: false)
        ]
    }

    static let subfolders = ["actions", "scripts", "tabs"]
}
