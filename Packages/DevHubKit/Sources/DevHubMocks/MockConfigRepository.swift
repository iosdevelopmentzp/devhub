import Foundation
import DevHubDomain

struct MockConfigRepository: ConfigRepository {
    func load(projectPath: String) async -> ResolvedConfig {
        MockData.resolvedConfig
    }

    func changes(projectPath: String) -> AsyncStream<Void> {
        AsyncStream { _ in }
    }

    func createExample(projectPath: String) async throws -> String {
        projectPath + "/" + ConfigPaths.folderName
    }

    func createStarter(projectPath: String, projectJSON: String) async throws -> String {
        projectPath + "/" + ConfigPaths.folderName + "/project.json"
    }

    func existingFolder(projectPath: String) async -> String? {
        projectPath + "/" + ConfigPaths.folderName
    }
}
