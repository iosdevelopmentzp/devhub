import Testing
@testable import DevHubDomain

@Suite struct MockServerPortPolicyTests {
    @Test func portIsStableAndInsideTheRange() {
        let port = MockServerPortPolicy.port(for: "6CD6212B-41FC-4B75-AA39-D4F22C7B67C9")

        #expect(port == MockServerPortPolicy.port(for: "6CD6212B-41FC-4B75-AA39-D4F22C7B67C9"))
        #expect(port >= MockServerPortPolicy.firstPort)
        #expect(port < MockServerPortPolicy.firstPort + MockServerPortPolicy.portCount)
        #expect(port != MockServerPortPolicy.port(for: "other"))
    }
}
