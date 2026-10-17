import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockSimulatorMessagingRepositoryTests {
    @Test func openURLDoesNotThrow() async throws {
        try await MockSimulatorMessagingRepository().openURL("app://open", udid: "sim")
    }
}
