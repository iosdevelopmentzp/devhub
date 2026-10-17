import Foundation
import DevHubDomain

struct MockExchangeHandler: Sendable {
    static let webSocketMessage = "WebSocket not mocked yet"

    let upstream: URL
    let rules: [MockRule]
    let forwarder: HTTPForwarder

    func handle(_ request: MockHTTPRequest, id: Int, startedAt: Date) async -> (response: MockHTTPResponse, exchange: NetworkRequest) {
        let clock = ContinuousClock()
        let start = clock.now
        let rule = request.isWebSocketUpgrade ? nil : MockRuleMatcher.match(method: request.method, path: request.path, query: request.query, in: rules)
        let (response, error) = await response(for: request, rule: rule)
        let elapsed = clock.now - start
        let exchange = NetworkRequest(
            id: id,
            method: request.method,
            url: HTTPForwarder.url(upstream: upstream, target: request.target)?.absoluteString ?? request.target,
            path: request.path,
            host: upstream.host ?? "",
            statusCode: response.status,
            statusText: HTTPResponseSerializer.reasonPhrase(response.status),
            startedAt: startedAt,
            duration: Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18,
            requestBody: Self.text(request.body),
            responseBody: Self.text(response.body),
            responseHeaders: response.headers,
            error: error,
            isFailure: error != nil || response.status >= 400,
            mockRuleID: rule?.id,
            requestHeaders: request.headers
        )
        return (response, NetworkRequestRedactor.redact(exchange))
    }

    private func response(for request: MockHTTPRequest, rule: MockRule?) async -> (MockHTTPResponse, String?) {
        if request.isWebSocketUpgrade {
            return (.text(501, Self.webSocketMessage), Self.webSocketMessage)
        }
        switch rule?.action {
        case .respond(let mock):
            await Self.wait(mock.delay)
            return (Self.response(from: mock), nil)
        case .patch(let patch):
            let (forwarded, error) = await forward(request)
            await Self.wait(patch.delay)
            guard error == nil, JSONPatcher.isJSON(forwarded.body) else { return (forwarded, error) }
            var patched = forwarded
            patched.body = JSONPatcher.apply(patch.operations, to: forwarded.body)
            return (patched, nil)
        case nil:
            return await forward(request)
        }
    }

    private func forward(_ request: MockHTTPRequest) async -> (MockHTTPResponse, String?) {
        do {
            return (try await forwarder.forward(request, to: upstream), nil)
        } catch {
            let message = "Upstream \(upstream.host ?? "host") failed: \(error.localizedDescription)"
            return (.jsonError(502, message), message)
        }
    }

    private static func response(from mock: MockResponse) -> MockHTTPResponse {
        var headers = mock.headers
        let hasContentType = headers.contains { $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame }
        if hasContentType == false, mock.body.isEmpty == false {
            headers.append(HTTPHeader(name: "Content-Type", value: JSONPatcher.isJSON(Data(mock.body.utf8)) ? "application/json" : "text/plain; charset=utf-8"))
        }
        return MockHTTPResponse(status: mock.status, headers: headers, body: Data(mock.body.utf8))
    }

    private static func wait(_ delay: TimeInterval) async {
        guard delay > 0 else { return }
        try? await Task.sleep(for: .milliseconds(Int(delay * 1000)))
    }

    private static func text(_ data: Data) -> String {
        guard data.isEmpty == false else { return "" }
        return String(data: data, encoding: .utf8) ?? "<\(data.count) bytes of binary data>"
    }
}
