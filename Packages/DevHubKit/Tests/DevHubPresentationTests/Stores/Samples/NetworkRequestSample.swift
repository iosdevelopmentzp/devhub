import Foundation
import DevHubDomain

enum NetworkRequestSample {
    static let ok = make(id: 1, method: "GET", path: "/v1/profile/info", statusCode: 200, duration: 0.2, isFailure: false)
    static let failed = make(id: 2, method: "POST", path: "/v1/chat/messages", statusCode: 422, duration: 0.3, isFailure: true)
    static let slow = make(id: 3, method: "GET", path: "/v1/leaderboard", statusCode: 200, duration: 1.5, isFailure: false)

    static let fromScript = NetworkRequest(
        id: 1 << 40,
        method: "GET",
        url: "https://api-qa.example.com/v1/settings/list",
        path: "/v1/settings/list",
        host: "api-qa.example.com",
        statusCode: 200,
        statusText: "",
        startedAt: nil,
        duration: 0.1,
        requestBody: "",
        responseBody: "",
        responseHeaders: [],
        error: nil,
        isFailure: false,
        origin: .sourceScript
    )

    static func make(id: Int, method: String, path: String, statusCode: Int?, duration: TimeInterval?, isFailure: Bool) -> NetworkRequest {
        NetworkRequest(
            id: id,
            method: method,
            url: "https://api-qa.example.com\(path)",
            path: path,
            host: "api-qa.example.com",
            statusCode: statusCode,
            statusText: "",
            startedAt: nil,
            duration: duration,
            requestBody: "",
            responseBody: "",
            responseHeaders: [],
            error: nil,
            isFailure: isFailure
        )
    }
}
