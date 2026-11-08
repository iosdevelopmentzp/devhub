import Foundation
import DevHubDomain

struct MockExchangeHandler: Sendable {
    let upstream: MockUpstream
    let rules: [MockRule]
    let forwarder: HTTPForwarder

    func handle(_ request: MockHTTPRequest, id: Int, startedAt: Date) async -> (response: MockHTTPResponse, exchange: NetworkRequest) {
        let clock = ContinuousClock()
        let start = clock.now
        let requestBody = Self.text(request.body)
        let operations = GraphQLParser.exchange(method: request.method, query: request.query, requestBody: requestBody, responseBody: "")?.operationNames ?? []
        let target = upstream.url(forPath: request.path)
        let rule = MockRuleMatcher.match(method: request.method, path: request.path, query: request.query, operationNames: operations, in: rules)
        let (response, error) = await response(for: request, rule: rule, target: target)
        let elapsed = clock.now - start
        let responseBody = Self.text(response.body)
        let graphQL = GraphQLParser.exchange(method: request.method, query: request.query, requestBody: requestBody, responseBody: responseBody)
        let exchange = NetworkRequest(
            id: id,
            method: request.method,
            url: HTTPForwarder.url(upstream: target, target: request.target)?.absoluteString ?? request.target,
            path: request.path,
            host: target.host ?? "",
            statusCode: response.status,
            statusText: HTTPResponseSerializer.reasonPhrase(response.status),
            startedAt: startedAt,
            duration: Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18,
            requestBody: requestBody,
            responseBody: responseBody,
            responseHeaders: response.headers,
            error: error,
            isFailure: error != nil || response.status >= 400 || graphQL?.errors.isEmpty == false,
            mockRuleID: rule?.id,
            requestHeaders: request.headers,
            graphQL: graphQL
        )
        return (response, NetworkRequestRedactor.redact(exchange))
    }

    private func response(for request: MockHTTPRequest, rule: MockRule?, target: URL) async -> (MockHTTPResponse, String?) {
        switch rule?.action {
        case .respond(let mock):
            await Self.wait(mock.delay)
            return (Self.response(from: mock), nil)
        case .patch(let patch):
            let (forwarded, error) = await forward(request, to: target)
            await Self.wait(patch.delay)
            guard error == nil, JSONPatcher.isJSON(forwarded.body) else { return (forwarded, error) }
            var patched = forwarded
            patched.body = JSONPatcher.apply(patch.operations, to: forwarded.body)
            return (patched, nil)
        case nil:
            return await forward(request, to: target)
        }
    }

    private func forward(_ request: MockHTTPRequest, to target: URL) async -> (MockHTTPResponse, String?) {
        do {
            return (try await forwarder.forward(request, to: target), nil)
        } catch {
            let message = "Upstream \(target.host ?? "host") failed: \(error.localizedDescription)"
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
