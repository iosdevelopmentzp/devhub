import Foundation

package protocol ConfigRepository: Sendable {
    func load(projectPath: String) async -> ResolvedConfig
    func changes(projectPath: String) -> AsyncStream<Void>
    func createExample(projectPath: String) async throws -> String
    func createStarter(projectPath: String, projectJSON: String) async throws -> String
    func existingFolder(projectPath: String) async -> String?
}
