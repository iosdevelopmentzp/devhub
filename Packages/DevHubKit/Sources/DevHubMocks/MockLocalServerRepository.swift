import Foundation
import DevHubDomain

actor MockLocalServerRepository: MockServerRepository {
    private var ports: [String: Int] = [:]
    private var upstreams: [String: MockUpstream] = [:]

    func start(udid: String, upstream: MockUpstream, rules: [MockRule], onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> Int {
        try await Task.sleep(for: .milliseconds(200))
        let port = ports[udid] ?? 52_000 + ports.count
        ports[udid] = port
        upstreams[udid] = upstream
        for request in MockData.mockServerExchanges {
            onExchange(request)
        }
        return port
    }

    func update(udid: String, rules: [MockRule]) async {}

    func stop(udid: String) async {
        ports[udid] = nil
        upstreams[udid] = nil
    }

    func port(udid: String) async -> Int? {
        ports[udid]
    }

    func upstream(udid: String) async -> MockUpstream? {
        upstreams[udid]
    }

    func retarget(udid: String, upstream: MockUpstream) async {
        guard ports[udid] != nil else { return }
        upstreams[udid] = upstream
    }
}
