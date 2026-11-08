import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubMocks

@Suite struct MockLocalServerRepositoryTests {
    @Test func startGivesAPortAndSampleExchangesUntilStopped() async throws {
        let repository = MockLocalServerRepository()
        let recorder = CallbackRecorder<NetworkRequest>()

        let port = try await repository.start(udid: "sim", upstream: MockUpstream(url: URL(string: "https://api-qa.example.com")!), rules: []) { recorder.append($0) }

        #expect(await repository.port(udid: "sim") == port)
        #expect(recorder.values == MockData.mockServerExchanges)
        await repository.stop(udid: "sim")
        #expect(await repository.port(udid: "sim") == nil)
    }
}
