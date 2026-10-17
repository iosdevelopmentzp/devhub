import Foundation

final class StubURLRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var handlers: [String: StubURLProtocol.Handler] = [:]
    private var requests: [String: [URLRequest]] = [:]

    func register(host: String, handler: @escaping StubURLProtocol.Handler) {
        lock.withLock {
            handlers[host] = handler
            requests[host] = []
        }
    }

    func handler(for host: String) -> StubURLProtocol.Handler? {
        lock.withLock { handlers[host] }
    }

    func record(_ request: URLRequest, host: String) {
        lock.withLock { requests[host, default: []].append(request) }
    }

    func requests(for host: String) -> [URLRequest] {
        lock.withLock { requests[host] ?? [] }
    }
}
