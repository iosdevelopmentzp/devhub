import DevHubDomain
import Foundation

package final class SpyNetworkSourceRepository: NetworkSourceRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [ScriptRunRequest] = []
    private var _events: [NetworkSourceEvent]?
    private var continuation: AsyncThrowingStream<NetworkSourceEvent, any Error>.Continuation?

    package init() {}

    package var calls: [ScriptRunRequest] {
        lock.withLock { _calls }
    }

    package var events: [NetworkSourceEvent]? {
        get { lock.withLock { _events } }
        set { lock.withLock { _events = newValue } }
    }

    package func follow(_ request: ScriptRunRequest) -> AsyncThrowingStream<NetworkSourceEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream<NetworkSourceEvent, any Error>.makeStream()
        let preset = lock.withLock {
            _calls.append(request)
            self.continuation = continuation
            return _events
        }
        if let preset {
            preset.forEach { continuation.yield($0) }
            continuation.finish()
        }
        return stream
    }

    package func emit(_ event: NetworkSourceEvent) {
        lock.withLock { continuation }?.yield(event)
    }

    package func finish(throwing error: (any Error)? = nil) {
        let open = lock.withLock { continuation }
        if let error {
            open?.finish(throwing: error)
        } else {
            open?.finish()
        }
    }
}
