import Foundation

package protocol MockSetRepository: Sendable {
    func list(project: String) async throws -> [MockSet]
    func save(_ set: MockSet, project: String) async throws
    func delete(id: MockSet.ID, project: String) async throws
}
