import Foundation

nonisolated protocol ConfigWatching: AnyObject {
    func stop()
}

nonisolated protocol ConfigProviding: Sendable {
    func load(projectPath: String) async -> ResolvedConfig
    func makeWatcher(projectPath: String, onChange: @escaping @Sendable () -> Void) -> ConfigWatching?
    func createExample(projectPath: String) throws -> String
    func folderToReveal(projectPath: String) -> String?
}

nonisolated struct MockConfigProvider: ConfigProviding {
    func load(projectPath: String) async -> ResolvedConfig {
        let files = ExampleConfig.layerFiles(layer: .project, directory: projectPath + "/" + ConfigPaths.folderName)
        return ConfigMerge.resolve([files])
    }

    func makeWatcher(projectPath: String, onChange: @escaping @Sendable () -> Void) -> ConfigWatching? {
        nil
    }

    func createExample(projectPath: String) throws -> String {
        projectPath + "/" + ConfigPaths.folderName
    }

    func folderToReveal(projectPath: String) -> String? {
        projectPath + "/" + ConfigPaths.folderName
    }
}
