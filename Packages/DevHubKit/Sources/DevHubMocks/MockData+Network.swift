import Foundation
import DevHubDomain

extension MockData {
    package static let networkRequests: [NetworkRequest] = [
        request(1, "GET", "/v1/profile/info", status: 200, text: "no error", duration: 0.182, seconds: 40, requestBody: "", body: #"{"data":{"profile":{"name":"Test User","humanReadableId":100200,"isVIP":false}}}"#),
        request(2, "GET", "/v1/settings/list", status: 200, text: "no error", duration: 0.094, seconds: 38, requestBody: "", body: #"{"data":{"chatEnabled":true,"giftsEnabled":true}}"#),
        request(3, "POST", "/v1/chat/messages", status: 201, text: "created", duration: 0.311, seconds: 30, requestBody: #"{"chatId":"chat-1","text":"Hello"}"#, body: #"{"data":{"id":"msg-42","status":"sent"}}"#),
        request(4, "GET", "/v1/leaderboard/top?period=week", status: 200, text: "no error", duration: 1.42, seconds: 25, requestBody: "", body: #"{"data":{"items":[{"rank":1,"name":"Alice"},{"rank":2,"name":"Bob"}]}}"#),
        request(5, "PATCH", "/v1/profile/settings", status: 422, text: "unprocessable entity", duration: 0.205, seconds: 18, requestBody: #"{"language":"xx"}"#, body: #"{"error":{"code":"invalid_language","message":"Language is not supported"}}"#),
        request(6, "DELETE", "/v1/chat/messages/msg-40", status: 204, text: "no content", duration: 0.12, seconds: 12, requestBody: "", body: ""),
        request(7, "GET", "/v1/gifts/catalog", status: 503, text: "service unavailable", duration: 2.8, seconds: 8, requestBody: "", body: #"{"error":{"code":"maintenance"}}"#),
        NetworkRequest(
            id: 8,
            method: "GET",
            url: "https://api-qa.example.com/v1/streams/live",
            path: "/v1/streams/live",
            host: "api-qa.example.com",
            statusCode: nil,
            statusText: "",
            startedAt: ago(minutes: 0.05),
            duration: nil,
            requestBody: "",
            responseBody: "",
            responseHeaders: [],
            error: "The request timed out.",
            isFailure: true
        )
    ]

    private static func request(
        _ id: Int,
        _ method: String,
        _ path: String,
        status: Int,
        text: String,
        duration: TimeInterval,
        seconds: Double,
        requestBody: String,
        body: String
    ) -> NetworkRequest {
        NetworkRequest(
            id: id,
            method: method,
            url: "https://api-qa.example.com\(path)",
            path: path,
            host: "api-qa.example.com",
            statusCode: status,
            statusText: text,
            startedAt: ago(minutes: seconds / 60),
            duration: duration,
            requestBody: requestBody,
            responseBody: body,
            responseHeaders: [
                HTTPHeader(name: "Content-Type", value: "application/json; charset=utf-8"),
                HTTPHeader(name: "X-Request-Id", value: "req-\(id)-0000"),
                HTTPHeader(name: "Server", value: "example")
            ],
            error: nil,
            isFailure: status >= 400
        )
    }
}
