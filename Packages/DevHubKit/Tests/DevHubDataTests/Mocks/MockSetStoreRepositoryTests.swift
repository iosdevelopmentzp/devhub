import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockSetStoreRepositoryTests {
    @Test func listsTheSampleSetsAndKeepsSavesAndDeletes() async throws {
        let repository = MockSetStoreRepository()
        let extra = MockSet(id: UUID(), name: "Extra", rules: [])

        #expect(try await repository.list(in: .defaultFolder(project: "app")) == MockData.mockSets)
        try await repository.save(extra, in: .defaultFolder(project: "app"))
        try await repository.delete(id: MockData.mockSetID, in: .defaultFolder(project: "app"))

        #expect(try await repository.list(in: .defaultFolder(project: "app")).map(\.name) == ["Empty wallet", "Extra"])
    }
}
