import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockSimulatorRepositoryTests {
    private let repository = MockSimulatorRepository()

    @Test func answersCannedData() async throws {
        #expect(try await repository.list() == MockData.simulatorGroups)
        #expect(await repository.installedAppCounts(udids: ["a", "b", "c", "d"]) == ["a": 0, "b": 1, "c": 2, "d": 0])
        try await repository.openInSimulatorApp(udid: "a")
        try await repository.resetKeychain(udid: "a")
        await repository.uninstallQuietly(udid: "a", bundleID: "com.example.app")
    }
}
