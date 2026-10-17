import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct HTTPForwarderTests {
    private let upstream = URL(string: "https://api-qa.example.com")!

    @Test func joinsUpstreamAndTarget() {
        #expect(HTTPForwarder.url(upstream: upstream, target: "/v1/x?a=1")?.absoluteString == "https://api-qa.example.com/v1/x?a=1")
        #expect(HTTPForwarder.url(upstream: URL(string: "http://host:8080/api/")!, target: "/v1/x")?.absoluteString == "http://host:8080/api/v1/x")
    }

    @Test func copiesMethodBodyAndHeadersButDropsHopByHopOnes() throws {
        let request = HTTPRequestFixture.request("POST", "/v1/chat", headers: [
            HTTPHeader(name: "Host", value: "127.0.0.1:52001"),
            HTTPHeader(name: "Connection", value: "keep-alive"),
            HTTPHeader(name: "Accept-Encoding", value: "gzip, br"),
            HTTPHeader(name: "Content-Length", value: "2"),
            HTTPHeader(name: "Authorization", value: "Bearer abc"),
            HTTPHeader(name: "X-App-Version", value: "5.1")
        ], body: "{}")

        let urlRequest = try #require(HTTPForwarder.urlRequest(for: request, upstream: upstream))

        #expect(urlRequest.httpMethod == "POST")
        #expect(urlRequest.httpBody == Data("{}".utf8))
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
        #expect(urlRequest.value(forHTTPHeaderField: "X-App-Version") == "5.1")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept-Encoding") == "identity")
        #expect(urlRequest.value(forHTTPHeaderField: "Host") == nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Connection") == nil)
        #expect(urlRequest.value(forHTTPHeaderField: "Content-Length") == nil)
        #expect(urlRequest.httpShouldHandleCookies == false)
    }

    @Test func responseHeadersLoseEncodingLengthAndHopByHop() {
        let response = HTTPRequestFixture.response(url: upstream, status: 200, headers: [
            "Content-Type": "application/json",
            "Content-Encoding": "gzip",
            "Content-Length": "10",
            "Transfer-Encoding": "chunked",
            "Connection": "keep-alive",
            "X-Request-Id": "r1"
        ])

        let headers = HTTPForwarder.responseHeaders(of: response)

        #expect(headers == [HTTPHeader(name: "Content-Type", value: "application/json"), HTTPHeader(name: "X-Request-Id", value: "r1")])
    }
}
