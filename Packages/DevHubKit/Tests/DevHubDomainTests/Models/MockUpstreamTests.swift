import Foundation
import Testing
@testable import DevHubDomain

@Suite struct MockUpstreamTests {
    private let base = URL(string: "https://api-qa.example.com")!
    private let socket = URL(string: "https://socket-qa.example.com")!

    @Test func withoutARouteEveryPathGoesToTheBase() {
        #expect(MockUpstream(url: base).url(forPath: "/socket.io/") == base)
    }

    @Test func theLongestMatchingPrefixWins() {
        let admin = URL(string: "https://admin-qa.example.com")!
        let upstream = MockUpstream(url: base, routes: [MockRoute(path: "/socket.io/", upstream: socket), MockRoute(path: "/socket.io/admin", upstream: admin)])

        #expect(upstream.url(forPath: "/socket.io/?EIO=4") == socket)
        #expect(upstream.url(forPath: "/socket.io/admin/x") == admin)
        #expect(upstream.url(forPath: "/v1/profile") == base)
        #expect(upstream.host == "api-qa.example.com")
    }
}
