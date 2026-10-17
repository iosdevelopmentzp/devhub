import Foundation
import DevHubDomain
@testable import DevHubData

enum HTTPRequestFixture {
    static let getSettings = Data("GET /v1/settings/list?lang=en HTTP/1.1\r\nHost: 127.0.0.1:52001\r\nAuthorization: Bearer secret-token-123\r\nAccept-Encoding: gzip\r\nAccept: application/json\r\n\r\n".utf8)

    static let postMessage = Data("POST /v1/chat/messages HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\nContent-Length: 14\r\n\r\n{\"text\":\"Hi!\"}".utf8)

    static let webSocketUpgrade = Data("GET /socket.io/?EIO=4&transport=websocket HTTP/1.1\r\nHost: 127.0.0.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n".utf8)

    static func request(_ method: String, _ target: String, headers: [HTTPHeader], body: String) -> MockHTTPRequest {
        MockHTTPRequest(method: method, target: target, version: "HTTP/1.1", headers: headers, body: Data(body.utf8))
    }

    static func response(url: URL, status: Int, headers: [String: String]) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
    }
}
