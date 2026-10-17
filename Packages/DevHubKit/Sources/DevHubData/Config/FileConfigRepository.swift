import Foundation
import DevHubDomain

struct FileConfigRepository: ConfigRepository {
    let home: URL
    let pollInterval: Duration

    func load(projectPath: String) async -> ResolvedConfig {
        let infos = layers(projectPath)
        return await Task.detached {
            ConfigMergePolicy.resolve(infos.map(ConfigFolderReader.read))
        }.value
    }

    func changes(projectPath: String) -> AsyncStream<Void> {
        let paths = layers(projectPath).flatMap { info in
            [info.directory] + ConfigPaths.subfolders.map { info.directory + "/" + $0 }
        }
        let interval = pollInterval
        return AsyncStream { continuation in
            let watcher = ConfigWatcher(paths: paths, pollInterval: interval) {
                continuation.yield()
            }
            continuation.onTermination = { _ in
                watcher.stop()
            }
        }
    }

    func createExample(projectPath: String) async throws -> String {
        let folder = ProjectPath(projectPath).expanded + "/" + ConfigPaths.folderName
        try await Task.detached {
            try ExampleConfigWriter.write(ExampleConfig.files, into: folder)
        }.value
        return folder
    }

    func existingFolder(projectPath: String) async -> String? {
        let infos = layers(projectPath)
        return await Task.detached {
            let preferred: [ConfigLayer] = [.project, .user, .global]
            return preferred.lazy
                .compactMap { layer in infos.first { $0.layer == layer } }
                .first { FileManager.default.fileExists(atPath: $0.directory) }?
                .directory
        }.value
    }

    private func layers(_ projectPath: String) -> [ConfigLayerInfo] {
        ConfigPaths.layers(projectPath: ProjectPath(projectPath).expanded, home: home.path)
    }
}
