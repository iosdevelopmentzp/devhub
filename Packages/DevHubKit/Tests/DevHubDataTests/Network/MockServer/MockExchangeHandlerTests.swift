import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct MockExchangeHandlerTests {
    private let host = "exchange-\(UUID().uuidString.lowercased()).example.com"
    private let upstreamBody = #"{"data":{"profile":{"isVIP":false,"token":"abc123"}}}"#

    @Test func respondRuleNeverHitsTheNetwork() async {
        let rule = rule(.respond(MockResponse(status: 201, headers: [], body: #"{"ok":true}"#, delay: 0)))

        let result = await handler(rules: [rule]).handle(HTTPRequestFixture.request("GET", "/v1/settings/list", headers: [], body: ""), id: 7, startedAt: Date())

        #expect(result.response.status == 201)
        #expect(result.response.headers == [HTTPHeader(name: "Content-Type", value: "application/json")])
        #expect(String(decoding: result.response.body, as: UTF8.self) == #"{"ok":true}"#)
        #expect(StubURLProtocol.registry.requests(for: host).isEmpty)
        #expect(result.exchange.id == 7)
        #expect(result.exchange.mockRuleID == rule.id)
        #expect(result.exchange.host == host)
        #expect(result.exchange.url == "https://\(host)/v1/settings/list")
    }

    @Test func patchRuleForwardsThenChangesTheJSON() async throws {
        let rule = rule(.patch(MockPatch(operations: [JSONPatchOperation(keyPath: "data.profile.isVIP", value: "true")], delay: 0)))

        let result = await handler(rules: [rule]).handle(HTTPRequestFixture.request("GET", "/v1/settings/list", headers: [], body: ""), id: 1, startedAt: Date())

        let object = try #require(try JSONSerialization.jsonObject(with: result.response.body) as? [String: Any])
        #expect(((object["data"] as? [String: Any])?["profile"] as? [String: Any])?["isVIP"] as? Bool == true)
        #expect(StubURLProtocol.registry.requests(for: host).count == 1)
        #expect(result.exchange.mockRuleID == rule.id)
    }

    @Test func unmatchedRequestIsForwardedWithItsBodyAndHeaders() async throws {
        let request = HTTPRequestFixture.request("POST", "/v1/chat?x=1", headers: [HTTPHeader(name: "Authorization", value: "Bearer secret-token"), HTTPHeader(name: "Content-Length", value: "2")], body: "{}")

        let result = await handler(rules: []).handle(request, id: 1, startedAt: Date())

        let sent = try #require(StubURLProtocol.registry.requests(for: host).first)
        #expect(sent.url?.absoluteString == "https://\(host)/v1/chat?x=1")
        #expect(sent.httpMethod == "POST")
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
        #expect(result.response.status == 200)
        #expect(result.response.headers.contains { $0.name == "Content-Encoding" } == false)
        #expect(result.exchange.mockRuleID == nil)
        #expect(result.exchange.duration != nil)
    }

    @Test func exchangeIsRedactedBeforeItLeaves() async {
        let request = HTTPRequestFixture.request("GET", "/v1/me", headers: [HTTPHeader(name: "Authorization", value: "Bearer secret-token"), HTTPHeader(name: "Accept", value: "*/*")], body: "")

        let result = await handler(rules: []).handle(request, id: 1, startedAt: Date())

        #expect(result.exchange.requestHeaders == [HTTPHeader(name: "Accept", value: "*/*")])
        #expect(result.exchange.responseBody.contains("abc123") == false)
        #expect(String(decoding: result.response.body, as: UTF8.self).contains("abc123"))
    }

    @Test func webSocketUpgradeIsAnswered501AndRecordedWithAnError() async {
        let rule = rule(.respond(MockResponse(status: 200, headers: [], body: "", delay: 0)))
        let request = HTTPRequestFixture.request("GET", "/socket.io/?EIO=4", headers: [HTTPHeader(name: "Upgrade", value: "websocket")], body: "")

        let result = await handler(rules: [rule]).handle(request, id: 1, startedAt: Date())

        #expect(result.response.status == 501)
        #expect(result.exchange.error == "WebSocket not mocked yet")
        #expect(result.exchange.isFailure)
        #expect(result.exchange.mockRuleID == nil)
    }

    @Test func upstreamFailureBecomes502() async {
        let failing = MockExchangeHandler(
            upstream: URL(string: "https://\(host)")!,
            rules: [],
            forwarder: HTTPForwarder(session: StubURLProtocol.session(host: host) { _ in throw URLError(.notConnectedToInternet) })
        )

        let result = await failing.handle(HTTPRequestFixture.request("GET", "/v1/x", headers: [], body: ""), id: 1, startedAt: Date())

        #expect(result.response.status == 502)
        #expect(result.exchange.error?.hasPrefix("Upstream \(host) failed") == true)
    }

    @Test func aGraphQLRuleAnswersOnlyItsOperation() async {
        var rule = rule(.respond(MockResponse(status: 200, headers: [], body: #"{"data":{"profile":{"name":"sam"}}}"#, delay: 0)))
        rule.method = "POST"
        rule.pathPattern = "/graphql"
        rule.operationName = "GetProfile"
        let profile = #"{"operationName":"GetProfile","query":"query GetProfile { profile { name } }","variables":{"id":"1"}}"#
        let cart = #"{"query":"query GetCart { cart { total } }"}"#

        let mocked = await handler(rules: [rule]).handle(HTTPRequestFixture.request("POST", "/graphql", headers: [], body: profile), id: 1, startedAt: Date())
        let forwarded = await handler(rules: [rule]).handle(HTTPRequestFixture.request("POST", "/graphql", headers: [], body: cart), id: 2, startedAt: Date())

        #expect(mocked.exchange.mockRuleID == rule.id)
        #expect(mocked.exchange.graphQL?.operationNames == ["GetProfile"])
        #expect(forwarded.exchange.mockRuleID == nil)
        #expect(forwarded.exchange.graphQL?.operationNames == ["GetCart"])
    }

    @Test func graphQLErrorsMarkTheExchangeAsFailed() async {
        let rule = MockRule(id: UUID(), isEnabled: true, method: "POST", pathPattern: "/graphql", query: nil, action: .respond(MockResponse(status: 200, headers: [], body: #"{"errors":[{"message":"Not allowed"}]}"#, delay: 0)))

        let result = await handler(rules: [rule]).handle(HTTPRequestFixture.request("POST", "/graphql", headers: [], body: #"{"query":"mutation Save { save }"}"#), id: 1, startedAt: Date())

        #expect(result.response.status == 200)
        #expect(result.exchange.isFailure)
        #expect(result.exchange.graphQL?.errors == ["Not allowed"])
    }

    private func handler(rules: [MockRule]) -> MockExchangeHandler {
        let body = Data(upstreamBody.utf8)
        let session = StubURLProtocol.session(host: host) { request in
            (HTTPRequestFixture.response(url: request.url ?? URL(fileURLWithPath: "/"), status: 200, headers: ["Content-Type": "application/json", "Content-Encoding": "gzip"]), body)
        }
        return MockExchangeHandler(upstream: URL(string: "https://\(host)")!, rules: rules, forwarder: HTTPForwarder(session: session))
    }

    private func rule(_ action: MockAction) -> MockRule {
        MockRule(id: UUID(), isEnabled: true, method: "GET", pathPattern: "/v1/settings/list", query: nil, action: action)
    }
}
