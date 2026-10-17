import Foundation
import DevHubDomain

extension MockData {
    package static let resolvedConfig: ResolvedConfig = {
        let directory = "~/Documents/Projects/example-app/.devhub"
        let files = ExampleConfig.files
        let layer = ConfigLayerFiles(
            layer: .project,
            directory: directory,
            exists: true,
            projectFile: files.first { $0.path == "project.json" }.map { ConfigFile(name: $0.path, text: $0.text) },
            actionFiles: files.filter { $0.path.hasPrefix("actions/") }.map { ConfigFile(name: $0.path, text: $0.text) },
            scriptFiles: files.filter { $0.path.hasPrefix("scripts/") }.map { ScriptFile(name: $0.path, head: $0.text, isExecutable: $0.isExecutable) },
            tabFiles: files.filter { $0.path.hasPrefix("tabs/") }.map { ConfigFile(name: $0.path, text: $0.text) }
        )
        return ConfigMergePolicy.resolve([layer])
    }()
}
