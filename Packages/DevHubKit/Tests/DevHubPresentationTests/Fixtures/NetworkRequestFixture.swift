import Foundation
import DevHubDomain

enum NetworkRequestFixture {
    static let profile = NetworkRequest(
        id: 1,
        method: "get",
        url: "https://api-qa.example.com/v1/profile/info",
        path: "/v1/profile/info",
        host: "api-qa.example.com",
        statusCode: 200,
        statusText: "no error",
        startedAt: Date(timeIntervalSince1970: 1_767_348_001),
        duration: 0.182,
        requestBody: "",
        responseBody: #"{"b":1,"a":{"c":"x/y"}}"#,
        responseHeaders: [HTTPHeader(name: "Content-Type", value: "application/json")],
        error: nil,
        isFailure: false
    )

    static func with(
        method: String,
        statusCode: Int?,
        error: String?,
        isFailure: Bool,
        duration: TimeInterval?
    ) -> NetworkRequest {
        var request = profile
        request.method = method
        request.statusCode = statusCode
        request.error = error
        request.isFailure = isFailure
        request.duration = duration
        return request
    }
}
