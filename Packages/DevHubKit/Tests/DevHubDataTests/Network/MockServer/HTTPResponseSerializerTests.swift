import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct HTTPResponseSerializerTests {

    @Test func writesStatusHeadersLengthCloseAndBody() {
        let response = MockHTTPResponse(
            status: 200,
            headers: [HTTPHeader(name: "Content-Type", value: "application/json"), HTTPHeader(name: "Content-Length", value: "999"), HTTPHeader(name: "Connection", value: "keep-alive")],
            body: Data(#"{"ok":true}"#.utf8)
        )

        let text = String(decoding: HTTPResponseSerializer.data(for: response), as: UTF8.self)

        #expect(text == "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 11\r\nConnection: close\r\n\r\n{\"ok\":true}")
    }

    @Test func emptyBodyHasZeroLength() {
        let text = String(decoding: HTTPResponseSerializer.data(for: MockHTTPResponse(status: 204, headers: [], body: Data())), as: UTF8.self)

        #expect(text == "HTTP/1.1 204 No Content\r\nContent-Length: 0\r\nConnection: close\r\n\r\n")
    }

    @Test func newlinesInHeaderValuesCannotSplitTheResponse() {
        let response = MockHTTPResponse(status: 200, headers: [HTTPHeader(name: "X-Note", value: "a\r\nInjected: yes")], body: Data())

        let text = String(decoding: HTTPResponseSerializer.data(for: response), as: UTF8.self)

        #expect(text.contains("X-Note: a  Injected: yes\r\n"))
    }

    @Test func unknownStatusGetsAGenericReason() {
        #expect(HTTPResponseSerializer.reasonPhrase(299) == "Status 299")
        #expect(HTTPResponseSerializer.reasonPhrase(501) == "Not Implemented")
    }
}
