import Foundation

package protocol BuildRepository: Sendable {
    func schemes(projectPath: String) async -> [String]
    func clean(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws
    func build(_ request: BuildRequest, onEvent: @escaping @Sendable (BuildEvent) -> Void) async throws -> [String]
    func locateProduct(_ request: BuildRequest, hints: [String]) async throws -> BuildProduct
    func lastBuiltAppPath(projectPath: String, scheme: String, configuration: String) -> String?
}
