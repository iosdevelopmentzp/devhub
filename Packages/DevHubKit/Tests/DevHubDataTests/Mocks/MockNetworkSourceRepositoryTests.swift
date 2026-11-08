import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockNetworkSourceRepositoryTests {
    @Test func yieldsTheSampleRequestsRightAway() async throws {
        let run = ScriptRunRequest(executable: "/repo/network/source.sh", arguments: [], cwd: "/repo", environment: [:])
        var iterator = MockNetworkSourceRepository().follow(run).makeAsyncIterator()

        let first = try #require(try await iterator.next())

        #expect(first == .request(MockData.sourceScriptExchanges[0]))
    }
}
