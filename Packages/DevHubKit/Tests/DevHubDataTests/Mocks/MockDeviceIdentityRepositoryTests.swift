import DevHubDomain
import Testing
@testable import DevHubMocks
import DevHubTestSupport

@Suite struct MockDeviceIdentityRepositoryTests {
    private let repository = MockDeviceIdentityRepository()

    @Test func readsKnownAndUnknownSimulators() async throws {
        let known = try #require(MockData.identities.first)

        #expect(await repository.read(udid: known.key, config: .example) == known.value)
        #expect(await repository.read(udid: "unknown", config: .example) == .notInstalled)
    }

    @Test func setEnvironmentDoesNotThrow() async throws {
        try await repository.setEnvironment("qa", udid: "sim", config: .example)
    }
}
