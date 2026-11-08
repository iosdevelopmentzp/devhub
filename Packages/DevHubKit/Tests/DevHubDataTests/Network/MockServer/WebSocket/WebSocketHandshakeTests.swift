import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct WebSocketHandshakeTests {
    private let request = MockHTTPRequest(
        method: "GET",
        target: "/socket.io/?EIO=4&transport=websocket",
        version: "HTTP/1.1",
        headers: [
            HTTPHeader(name: "Host", value: "127.0.0.1:52001"),
            HTTPHeader(name: "Origin", value: "http://127.0.0.1:52001"),
            HTTPHeader(name: "Upgrade", value: "websocket"),
            HTTPHeader(name: "Connection", value: "Upgrade"),
            HTTPHeader(name: "Sec-WebSocket-Key", value: "dGhlIHNhbXBsZSBub25jZQ=="),
            HTTPHeader(name: "Sec-WebSocket-Extensions", value: "permessage-deflate"),
            HTTPHeader(name: "Authorization", value: "Bearer abc"),
        ],
        body: Data()
    )

    @Test func theRequestHeadPointsAtTheUpstreamAndDropsCompression() throws {
        let head = try #require(WebSocketHandshake.requestHead(for: request, upstream: URL(string: "https://socket-qa.example.com/base")!))

        #expect(String(decoding: head, as: UTF8.self) == [
            "GET /base/socket.io/?EIO=4&transport=websocket HTTP/1.1",
            "Host: socket-qa.example.com",
            "Origin: https://socket-qa.example.com",
            "Upgrade: websocket",
            "Connection: Upgrade",
            "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
            "Authorization: Bearer abc",
        ].joined(separator: "\r\n") + "\r\n\r\n")
    }

    @Test func aPortThatIsNotTheDefaultStaysInTheHost() throws {
        let head = try #require(WebSocketHandshake.requestHead(for: request, upstream: URL(string: "http://127.0.0.1:8080")!))

        #expect(String(decoding: head, as: UTF8.self).contains("Host: 127.0.0.1:8080\r\n"))
        #expect(WebSocketHandshake.endpoint(for: URL(string: "http://127.0.0.1:8080")!)! == ("127.0.0.1", 8080, false))
        #expect(WebSocketHandshake.endpoint(for: URL(string: "https://socket-qa.example.com")!)! == ("socket-qa.example.com", 443, true))
    }

    @Test func theURLUsesTheWebSocketScheme() {
        #expect(WebSocketHandshake.webSocketURL(upstream: URL(string: "https://socket-qa.example.com")!, target: "/socket.io/?EIO=4") == "wss://socket-qa.example.com/socket.io/?EIO=4")
        #expect(WebSocketHandshake.webSocketURL(upstream: URL(string: "http://127.0.0.1:8080")!, target: "/ws") == "ws://127.0.0.1:8080/ws")
    }

    @Test func theResponseHeadIsReadOnlyWhenComplete() {
        let bytes = Data("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nSec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n\r\n".utf8) + Data([0x81, 0x00])

        #expect(WebSocketHandshake.responseHead(in: bytes.prefix(20)) == nil)
        #expect(WebSocketHandshake.responseHead(in: bytes) == WebSocketHandshake.ResponseHead(
            status: 101,
            reason: "Switching Protocols",
            headers: [HTTPHeader(name: "Upgrade", value: "websocket"), HTTPHeader(name: "Sec-WebSocket-Accept", value: "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=")],
            length: bytes.count - 2
        ))
    }
}
