import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct HTTPRequestParserTests {

    @Test func parsesTheRequestLineHeadersAndQuery() throws {
        let request = try complete(HTTPRequestParser.parse(HTTPRequestFixture.getSettings))

        #expect(request.method == "GET")
        #expect(request.target == "/v1/settings/list?lang=en")
        #expect(request.path == "/v1/settings/list")
        #expect(request.query == "lang=en")
        #expect(request.version == "HTTP/1.1")
        #expect(request.header("accept") == "application/json")
        #expect(request.headers.count == 4)
        #expect(request.body.isEmpty)
    }

    @Test func readsTheBodyByContentLength() throws {
        let request = try complete(HTTPRequestParser.parse(HTTPRequestFixture.postMessage))

        #expect(request.method == "POST")
        #expect(String(decoding: request.body, as: UTF8.self) == #"{"text":"Hi!"}"#)
    }

    @Test func partialReadsAreIncompleteUntilTheLastByte() throws {
        let data = HTTPRequestFixture.postMessage

        #expect(HTTPRequestParser.parse(data.prefix(20)) == .incomplete)
        #expect(HTTPRequestParser.parse(data.prefix(data.count - 1)) == .incomplete)
        _ = try complete(HTTPRequestParser.parse(data))
    }

    @Test func extraBytesAfterTheBodyAreIgnored() throws {
        let request = try complete(HTTPRequestParser.parse(HTTPRequestFixture.postMessage + Data("GET".utf8)))

        #expect(request.body.count == 14)
    }

    @Test func malformedInputIsInvalid() {
        #expect(HTTPRequestParser.parse(Data("HELLO\r\n\r\n".utf8)) == .invalid("Malformed request line."))
        #expect(HTTPRequestParser.parse(Data("GET / HTTP/1.1\r\nContent-Length: x\r\n\r\n".utf8)) == .invalid("Malformed Content-Length."))
    }

    @Test func chunkedBodiesAreUnsupportedUnlessEmpty() throws {
        let head = "POST /v1/x HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n"

        guard case .unsupported = HTTPRequestParser.parse(Data((head + "5\r\nhello\r\n0\r\n\r\n").utf8)) else {
            Issue.record("Expected unsupported")
            return
        }
        #expect(HTTPRequestParser.parse(Data((head + "0\r\n").utf8)) == .incomplete)
        #expect(try complete(HTTPRequestParser.parse(Data((head + "0\r\n\r\n").utf8))).body.isEmpty)
    }

    @Test func detectsAWebSocketUpgrade() throws {
        let request = try complete(HTTPRequestParser.parse(HTTPRequestFixture.webSocketUpgrade))

        #expect(request.isWebSocketUpgrade)
        #expect(request.path == "/socket.io/")
    }

    private func complete(_ outcome: HTTPRequestParser.Outcome) throws -> MockHTTPRequest {
        guard case .complete(let request) = outcome else {
            throw TestError.scripted("\(outcome)")
        }
        return request
    }
}
