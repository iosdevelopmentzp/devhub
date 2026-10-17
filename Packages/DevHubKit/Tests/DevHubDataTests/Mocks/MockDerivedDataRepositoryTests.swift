import DevHubDomain
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockDerivedDataRepositoryTests {
    @Test func hasNoFolders() async throws {
        let repository = MockDerivedDataRepository()
        let folder = URL(fileURLWithPath: "/tmp/DerivedData/App")

        #expect(repository.folder(forCheckout: "~/App") == nil)
        #expect(await repository.size(of: folder) == nil)
        try repository.remove(folder)
    }
}
