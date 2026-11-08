import DevHubDomain
import Foundation

package final class SpyMockServerRepository: MockServerRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case start(udid: String, upstream: MockUpstream, rules: [MockRule])
        case update(udid: String, rules: [MockRule])
        case stop(udid: String)
        case port(udid: String)
        case upstream(udid: String)
        case retarget(udid: String, upstream: MockUpstream)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _startResult: Result<Int, any Error> = .success(52_001)
    private var _ports: [String: Int] = [:]
    private var _upstreams: [String: MockUpstream] = [:]
    private var _handlers: [String: @Sendable (NetworkRequest) -> Void] = [:]

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var startResult: Result<Int, any Error> {
        get { lock.withLock { _startResult } }
        set { lock.withLock { _startResult = newValue } }
    }

    package var ports: [String: Int] {
        get { lock.withLock { _ports } }
        set { lock.withLock { _ports = newValue } }
    }

    package func start(udid: String, upstream: MockUpstream, rules: [MockRule], onExchange: @escaping @Sendable (NetworkRequest) -> Void) async throws -> Int {
        try lock.withLock {
            _calls.append(.start(udid: udid, upstream: upstream, rules: rules))
            let port = try _startResult.get()
            _ports[udid] = port
            _upstreams[udid] = upstream
            _handlers[udid] = onExchange
            return port
        }
    }

    package func update(udid: String, rules: [MockRule]) async {
        lock.withLock { _calls.append(.update(udid: udid, rules: rules)) }
    }

    package func stop(udid: String) async {
        lock.withLock {
            _calls.append(.stop(udid: udid))
            _ports[udid] = nil
            _upstreams[udid] = nil
            _handlers[udid] = nil
        }
    }

    package func port(udid: String) async -> Int? {
        lock.withLock {
            _calls.append(.port(udid: udid))
            return _ports[udid]
        }
    }

    package var upstreams: [String: MockUpstream] {
        get { lock.withLock { _upstreams } }
        set { lock.withLock { _upstreams = newValue } }
    }

    package func upstream(udid: String) async -> MockUpstream? {
        lock.withLock {
            _calls.append(.upstream(udid: udid))
            return _upstreams[udid]
        }
    }

    package func retarget(udid: String, upstream: MockUpstream) async {
        lock.withLock {
            _calls.append(.retarget(udid: udid, upstream: upstream))
            _upstreams[udid] = upstream
        }
    }

    package func emit(_ request: NetworkRequest, udid: String) {
        lock.withLock { _handlers[udid] }?(request)
    }
}
