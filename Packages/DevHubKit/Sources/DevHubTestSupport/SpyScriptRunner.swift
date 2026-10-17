import DevHubDomain
import Foundation

package final class SpyScriptRunner: ScriptRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [ScriptRunRequest] = []
    private var _events: [ScriptEvent] = [.exited(0)]
    private var _runError: TestError? = nil
    private var _holdsOpen = false
    private var continuations: [AsyncThrowingStream<ScriptEvent, any Error>.Continuation] = []

    package init() {}

    package var calls: [ScriptRunRequest] {
        lock.withLock { _calls }
    }

    package var events: [ScriptEvent] {
        get { lock.withLock { _events } }
        set { lock.withLock { _events = newValue } }
    }

    package var runError: TestError? {
        get { lock.withLock { _runError } }
        set { lock.withLock { _runError = newValue } }
    }

    package var holdsOpen: Bool {
        get { lock.withLock { _holdsOpen } }
        set { lock.withLock { _holdsOpen = newValue } }
    }

    package func run(_ request: ScriptRunRequest) -> AsyncThrowingStream<ScriptEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream<ScriptEvent, any Error>.makeStream()
        let (events, error, holdsOpen) = lock.withLock {
            _calls.append(request)
            continuations.append(continuation)
            return (_events, _runError, _holdsOpen)
        }
        events.forEach { continuation.yield($0) }
        guard holdsOpen == false else { return stream }
        continuation.finish(throwing: error)
        return stream
    }

    package func finishAll() {
        lock.withLock { continuations }.forEach { $0.finish() }
    }
}
