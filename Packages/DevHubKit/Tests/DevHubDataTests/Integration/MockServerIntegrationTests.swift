import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration), .timeLimit(.minutes(1))) struct MockServerIntegrationTests {
    private let udid = "SIM-\(UUID().uuidString)"

    @Test func respondRuleIsServedOverARealSocket() async throws {
        let repository = NWMockServerRepository(session: .mockForwarding())
        let recorder = CallbackRecorder<NetworkRequest>()
        let rule = respondRule(path: "/v1/settings/list", status: 201, body: #"{"mocked":true}"#)
        let port = try await repository.start(udid: udid, upstream: URL(string: "https://unused.invalid")!, rules: [rule]) { recorder.append($0) }

        let (data, response) = try await get("http://127.0.0.1:\(port)/v1/settings/list")

        #expect(response.statusCode == 201)
        #expect(String(decoding: data, as: UTF8.self) == #"{"mocked":true}"#)
        try await waitUntil { recorder.values.count == 1 }
        #expect(recorder.values.first?.mockRuleID == rule.id)
        await repository.stop(udid: udid)
    }

    @Test func patchRuleChangesTheUpstreamResponseFromAnInjectedSession() async throws {
        let host = "patch-\(UUID().uuidString.lowercased()).example.com"
        let session = StubURLProtocol.session(host: host) { request in
            (HTTPRequestFixture.response(url: request.url ?? URL(fileURLWithPath: "/"), status: 200, headers: ["Content-Type": "application/json"]), Data(#"{"data":{"isVIP":false,"balance":10}}"#.utf8))
        }
        let repository = NWMockServerRepository(session: session)
        let patch = MockRule(
            id: UUID(),
            isEnabled: true,
            method: "GET",
            pathPattern: "/v1/profile/*",
            query: nil,
            action: .patch(MockPatch(operations: [JSONPatchOperation(keyPath: "data.isVIP", value: "true")], delay: 0))
        )
        let port = try await repository.start(udid: udid, upstream: URL(string: "https://\(host)")!, rules: [patch]) { _ in }

        let (data, response) = try await get("http://127.0.0.1:\(port)/v1/profile/info")

        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(response.statusCode == 200)
        #expect((object["data"] as? [String: Any])?["isVIP"] as? Bool == true)
        #expect((object["data"] as? [String: Any])?["balance"] as? Int == 10)
        await repository.stop(udid: udid)
    }

    @Test func unmatchedRouteIsForwardedToARealUpstream() async throws {
        let upstreamRepository = NWMockServerRepository(session: .mockForwarding())
        let upstreamPort = try await upstreamRepository.start(
            udid: "upstream",
            upstream: URL(string: "https://unused.invalid")!,
            rules: [respondRule(path: "/v1/real", status: 200, body: #"{"from":"upstream"}"#)]
        ) { _ in }
        let repository = NWMockServerRepository(session: .mockForwarding())
        let recorder = CallbackRecorder<NetworkRequest>()
        let port = try await repository.start(udid: udid, upstream: URL(string: "http://127.0.0.1:\(upstreamPort)")!, rules: [respondRule(path: "/v1/other", status: 500, body: "")]) { recorder.append($0) }

        let (data, response) = try await get("http://127.0.0.1:\(port)/v1/real?x=1")

        #expect(response.statusCode == 200)
        #expect(String(decoding: data, as: UTF8.self) == #"{"from":"upstream"}"#)
        try await waitUntil { recorder.values.count == 1 }
        #expect(recorder.values.first?.mockRuleID == nil)
        #expect(recorder.values.first?.host == "127.0.0.1")
        await repository.stop(udid: udid)
        await upstreamRepository.stop(udid: "upstream")
    }

    @Test func webSocketUpgradeIsAnswered501() async throws {
        let repository = NWMockServerRepository(session: .mockForwarding())
        let recorder = CallbackRecorder<NetworkRequest>()
        let port = try await repository.start(udid: udid, upstream: URL(string: "https://unused.invalid")!, rules: []) { recorder.append($0) }

        let reply = String(decoding: try await RawHTTPClient.send(HTTPRequestFixture.webSocketUpgrade, port: port), as: UTF8.self)

        #expect(reply.hasPrefix("HTTP/1.1 501 Not Implemented\r\n"))
        #expect(reply.contains("Connection: close"))
        try await waitUntil { recorder.values.count == 1 }
        #expect(recorder.values.first?.error == "WebSocket not mocked yet")
        await repository.stop(udid: udid)
    }

    @Test func startingTwiceKeepsThePortAndSwapsTheRules() async throws {
        let repository = NWMockServerRepository(session: .mockForwarding())
        let first = try await repository.start(udid: udid, upstream: URL(string: "https://unused.invalid")!, rules: [respondRule(path: "/v1/x", status: 200, body: "one")]) { _ in }
        let second = try await repository.start(udid: udid, upstream: URL(string: "https://unused.invalid")!, rules: [respondRule(path: "/v1/x", status: 200, body: "two")]) { _ in }
        await repository.update(udid: udid, rules: [respondRule(path: "/v1/x", status: 200, body: "three")])

        let (data, _) = try await get("http://127.0.0.1:\(second)/v1/x")

        #expect(first == second)
        #expect(String(decoding: data, as: UTF8.self) == "three")
        await repository.stop(udid: udid)
    }

    @Test func stopClosesThePort() async throws {
        let repository = NWMockServerRepository(session: .mockForwarding())
        let port = try await repository.start(udid: udid, upstream: URL(string: "https://unused.invalid")!, rules: []) { _ in }

        await repository.stop(udid: udid)

        #expect(await repository.port(udid: udid) == nil)
        await #expect(throws: (any Error).self) {
            _ = try await RawHTTPClient.send(Data("GET / HTTP/1.1\r\n\r\n".utf8), port: port)
        }
    }

    private func respondRule(path: String, status: Int, body: String) -> MockRule {
        MockRule(id: UUID(), isEnabled: true, method: nil, pathPattern: path, query: nil, action: .respond(MockResponse(status: status, headers: [], body: body, delay: 0)))
    }

    private func get(_ url: String) async throws -> (Data, HTTPURLResponse) {
        let session = URLSession(configuration: .ephemeral)
        let (data, response) = try await session.data(from: try #require(URL(string: url)))
        return (data, try #require(response as? HTTPURLResponse))
    }
}
