import Foundation

package enum MockRuleFactory {

    package static func respondRule(from request: NetworkRequest, id: UUID) -> MockRule {
        let method = request.method.trimmed.uppercased()
        let contentType = request.responseHeaders.first { $0.name.caseInsensitiveCompare("Content-Type") == .orderedSame }
        return MockRule(
            id: id,
            isEnabled: true,
            method: method.isEmpty ? nil : method,
            pathPattern: path(of: request),
            query: nil,
            action: .respond(MockResponse(
                status: request.statusCode ?? 200,
                headers: contentType.map { [$0] } ?? [],
                body: request.responseBody,
                delay: 0
            )),
            operationName: request.graphQL?.operationNames.first
        )
    }

    package static func newRule(id: UUID) -> MockRule {
        MockRule(
            id: id,
            isEnabled: true,
            method: "GET",
            pathPattern: "/v1/",
            query: nil,
            action: .respond(MockResponse(status: 200, headers: [], body: "{}", delay: 0))
        )
    }

    private static func path(of request: NetworkRequest) -> String {
        let raw = request.path.isEmpty ? (URL(string: request.url)?.path ?? "") : request.path
        let path = raw.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        return path.isEmpty ? "/" : path
    }
}
