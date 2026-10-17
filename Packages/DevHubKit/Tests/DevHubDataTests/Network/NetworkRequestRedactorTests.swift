import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct NetworkRequestRedactorTests {
    @Test func dropsCredentialHeadersEntirely() {
        let request = sample(headers: [
            HTTPHeader(name: "authorization", value: "x"),
            HTTPHeader(name: "Cookie", value: "a=b"),
            HTTPHeader(name: "Set-Cookie", value: "a=b"),
            HTTPHeader(name: "Proxy-Authorization", value: "x"),
            HTTPHeader(name: "Content-Length", value: "12"),
        ])

        #expect(NetworkRequestRedactor.redact(request).responseHeaders == [HTTPHeader(name: "Content-Length", value: "12")])
    }

    @Test func masksTokenValuesInTheQueryBodiesHeadersAndError() {
        let request = sample(headers: [HTTPHeader(name: "X-Trace", value: "Bearer abc")])

        let redacted = NetworkRequestRedactor.redact(request)

        #expect(redacted.url == "https://api-qa.example.com/v1/items?token=•••&page=2")
        #expect(redacted.requestBody == #"{"refresh_token":"•••"}"#)
        #expect(redacted.responseBody == #"{"api_key":"•••"}"#)
        #expect(redacted.responseHeaders == [HTTPHeader(name: "X-Trace", value: "Bearer •••")])
        #expect(redacted.error == "failed with password=•••")
    }

    @Test func requestHeadersLoseCredentialsAndMaskTokens() {
        var request = sample(headers: [])
        request.requestHeaders = [
            HTTPHeader(name: "Authorization", value: "Bearer abc"),
            HTTPHeader(name: "Cookie", value: "sid=1"),
            HTTPHeader(name: "X-Auth-Token", value: "abc"),
            HTTPHeader(name: "Accept", value: "application/json"),
        ]

        let redacted = NetworkRequestRedactor.redact(request)

        #expect(redacted.requestHeaders == [HTTPHeader(name: "X-Auth-Token", value: "•••"), HTTPHeader(name: "Accept", value: "application/json")])
    }

    private func sample(headers: [HTTPHeader]) -> NetworkRequest {
        NetworkRequest(
            id: 1,
            method: "GET",
            url: "https://api-qa.example.com/v1/items?token=abc123&page=2",
            path: "/v1/items",
            host: "api-qa.example.com",
            statusCode: 200,
            statusText: "",
            startedAt: nil,
            duration: nil,
            requestBody: #"{"refresh_token":"abc"}"#,
            responseBody: #"{"api_key":"abc"}"#,
            responseHeaders: headers,
            error: "failed with password=abc",
            isFailure: false
        )
    }
}
