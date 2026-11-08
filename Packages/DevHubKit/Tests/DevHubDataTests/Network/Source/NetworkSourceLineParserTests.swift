import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct NetworkSourceLineParserTests {
    private func parse(_ line: String) -> NetworkSourceLineParser.Line {
        NetworkSourceLineParser.parse(line, id: { $0 == "r-1" ? 7 : 9 })
    }

    @Test func aFullRequestBecomesAScriptRequest() throws {
        let line = #"@devhub {"request": {"id": "r-1", "method": "post", "url": "https://api.example.com/v1/chat?x=1", "status": 422, "statusText": "invalid", "startedAt": "2026-11-06T08:15:30.702Z", "durationMs": 250, "requestHeaders": {"Content-Type": "application/json", "Authorization": "Bearer abc"}, "requestBody": "{\"text\":\"hi\"}", "responseHeaders": {"X-Trace": "t-1"}, "responseBody": "{\"error\":\"bad\"}"}}"#

        guard case let .request(request) = parse(line) else {
            Issue.record("Not a request")
            return
        }

        #expect(request.id == 7)
        #expect(request.method == "POST")
        #expect(request.url == "https://api.example.com/v1/chat?x=1")
        #expect(request.path == "/v1/chat")
        #expect(request.host == "api.example.com")
        #expect(request.statusCode == 422)
        #expect(request.statusText == "invalid")
        #expect(request.startedAt == ISO8601.date(from: "2026-11-06T08:15:30.702Z"))
        #expect(request.duration == 0.25)
        #expect(request.isFailure)
        #expect(request.origin == .sourceScript)
        #expect(request.requestHeaders == [HTTPHeader(name: "Content-Type", value: "application/json")])
        #expect(request.responseHeaders == [HTTPHeader(name: "X-Trace", value: "t-1")])
        #expect(request.requestBody == #"{"text":"hi"}"#)
    }

    @Test func aShortRequestNeedsOnlyMethodAndURL() {
        guard case let .request(request) = parse(#"@devhub {"request": {"method": "GET", "url": "/v1/profile/info?x=1", "startedAt": 1762416930.5}}"#) else {
            Issue.record("Not a request")
            return
        }

        #expect(request.id == 9)
        #expect(request.path == "/v1/profile/info")
        #expect(request.host == "")
        #expect(request.statusCode == nil)
        #expect(request.startedAt == Date(timeIntervalSince1970: 1762416930.5))
        #expect(request.isFailure == false)
    }

    @Test func aMissingFieldOrABadDateIsAnError() {
        #expect(parse(#"@devhub {"request": {"method": "GET"}}"#) == .error("The request directive has no url."))
        guard case let .error(message) = parse(#"@devhub {"request": {"method": "GET", "url": "/x", "startedAt": "yesterday"}}"#) else {
            Issue.record("Not an error")
            return
        }
        #expect(message.contains("startedAt"))
    }

    @Test func otherLinesAreKeptApart() {
        #expect(parse("reading log-2026.11.06.txt") == .other)
        #expect(parse(#"@devhub {"toast": "hi"}"#) == .other)
        #expect(parse(#"@devhub {"error": "No log file yet"}"#) == .error("No log file yet"))
        #expect(parse("@devhub not json") == .error("A network source line is not one JSON object."))
    }

    @Test func aLongBodyIsCut() {
        let body = String(repeating: "a", count: NetworkSourceLineParser.maxBody + 10)
        guard case let .request(request) = parse(#"@devhub {"request": {"method": "GET", "url": "/x", "responseBody": "\#(body)"}}"#) else {
            Issue.record("Not a request")
            return
        }

        #expect(request.responseBody.hasSuffix("cut at 512 KB"))
    }
}
