import Foundation
import DevHubDomain

actor MockSetStoreRepository: MockSetRepository {
    private var sets = MockData.mockSets

    func list(in location: MockSetLocation) async throws -> [MockSet] {
        sets
    }

    func save(_ set: MockSet, in location: MockSetLocation) async throws {
        if let index = sets.firstIndex(where: { $0.id == set.id }) {
            sets[index] = set
        } else {
            sets.append(set)
        }
    }

    func delete(id: MockSet.ID, in location: MockSetLocation) async throws {
        sets.removeAll { $0.id == id }
    }
}
