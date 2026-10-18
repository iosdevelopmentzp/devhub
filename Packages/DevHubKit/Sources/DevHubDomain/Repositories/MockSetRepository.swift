import Foundation

package protocol MockSetRepository: Sendable {
    func list(in location: MockSetLocation) async throws -> [MockSet]
    func save(_ set: MockSet, in location: MockSetLocation) async throws
    func delete(id: MockSet.ID, in location: MockSetLocation) async throws
}
