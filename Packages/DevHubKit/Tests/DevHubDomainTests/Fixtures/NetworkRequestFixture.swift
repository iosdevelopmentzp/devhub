import Foundation
@testable import DevHubDomain

enum NetworkRequestFixture {
    static func request(statusCode: Int?, duration: TimeInterval?, isFailure: Bool) -> NetworkRequest {
        NetworkRequest(
            id: 1,
            method: "GET",
            url: "https://api-qa.example.com/v1/x",
            path: "/v1/x",
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
