import DevHubDomain
import Testing
@testable import DevHubMocks
import DevHubTestSupport

@Suite struct MockAppLaunchRepositoryTests {
    private let repository = MockAppLaunchRepository()
    private let identity = LaunchIdentityConfig(variable: "APP_DEVICE_ID")

    @Test func inspectsKnownAndUnknownSimulators() async throws {
        let known = try #require(MockData.installedApps.first)

        #expect(await repository.inspect(udid: known.key, bundleID: "com.example.app", identity: identity, storage: nil) == known.value)
        #expect(await repository.inspect(udid: "unknown", bundleID: "com.example.app", identity: identity, storage: nil) == .notInstalled)
    }
}
