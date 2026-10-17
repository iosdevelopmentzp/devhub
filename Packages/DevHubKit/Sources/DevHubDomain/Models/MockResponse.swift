import Foundation

package struct MockResponse: Hashable, Sendable {
    package var status: Int
    package var headers: [HTTPHeader]
    package var body: String
    package var delay: TimeInterval

    package init(status: Int, headers: [HTTPHeader], body: String, delay: TimeInterval) {
        self.status = status
        self.headers = headers
        self.body = body
        self.delay = delay
    }
}
