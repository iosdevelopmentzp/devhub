import Foundation

package struct NetworkRequest: Identifiable, Hashable, Sendable {
    package let id: Int
    package var method: String
    package var url: String
    package var path: String
    package var host: String
    package var statusCode: Int?
    package var statusText: String
    package var startedAt: Date?
    package var duration: TimeInterval?
    package var requestBody: String
    package var responseBody: String
    package var responseHeaders: [HTTPHeader]
    package var error: String?
    package var isFailure: Bool
    package var mockRuleID: MockRule.ID? = nil
    package var requestHeaders: [HTTPHeader] = []
    package var graphQL: GraphQLExchange? = nil
    package var origin: NetworkRequestOrigin = .mockServer

    package init(
        id: Int,
        method: String,
        url: String,
        path: String,
        host: String,
        statusCode: Int?,
        statusText: String,
        startedAt: Date?,
        duration: TimeInterval?,
        requestBody: String,
        responseBody: String,
        responseHeaders: [HTTPHeader],
        error: String?,
        isFailure: Bool,
        mockRuleID: MockRule.ID? = nil,
        requestHeaders: [HTTPHeader] = [],
        graphQL: GraphQLExchange? = nil,
        origin: NetworkRequestOrigin = .mockServer
    ) {
        self.id = id
        self.method = method
        self.url = url
        self.path = path
        self.host = host
        self.statusCode = statusCode
        self.statusText = statusText
        self.startedAt = startedAt
        self.duration = duration
        self.requestBody = requestBody
        self.responseBody = responseBody
        self.responseHeaders = responseHeaders
        self.error = error
        self.isFailure = isFailure
        self.mockRuleID = mockRuleID
        self.requestHeaders = requestHeaders
        self.graphQL = graphQL
        self.origin = origin
    }

    package var isWebSocket: Bool {
        requestHeaders.contains { $0.name.caseInsensitiveCompare("Upgrade") == .orderedSame && $0.value.lowercased() == "websocket" }
    }
}
