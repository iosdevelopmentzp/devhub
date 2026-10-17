import Foundation
import DevHubDomain

struct MockHTTPResponse: Equatable, Sendable {
    var status: Int
    var headers: [HTTPHeader]
    var body: Data

    static func text(_ status: Int, _ message: String) -> MockHTTPResponse {
        MockHTTPResponse(
            status: status,
            headers: [HTTPHeader(name: "Content-Type", value: "text/plain; charset=utf-8")],
            body: Data(message.utf8)
        )
    }

    static func jsonError(_ status: Int, _ message: String) -> MockHTTPResponse {
        let object = ["error": ["message": message, "source": "DevHub mock server"]]
        let body = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return MockHTTPResponse(status: status, headers: [HTTPHeader(name: "Content-Type", value: "application/json")], body: body)
    }
}
