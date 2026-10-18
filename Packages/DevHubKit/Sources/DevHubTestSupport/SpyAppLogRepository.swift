import DevHubDomain
import Foundation

package final class SpyAppLogRepository: AppLogRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case executableName(udid: String, bundleID: String)
        case stream(udid: String, filter: AppLogFilter)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _executableNameResult: String? = nil
    private var continuations: [String: AsyncThrowingStream<AppLogLine, Error>.Continuation] = [:]

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var executableNameResult: String? {
        get { lock.withLock { _executableNameResult } }
        set { lock.withLock { _executableNameResult = newValue } }
    }

    package func executableName(udid: String, bundleID: String) async -> String? {
        record(.executableName(udid: udid, bundleID: bundleID)) { _executableNameResult }
    }

    package func stream(udid: String, filter: AppLogFilter) -> AsyncThrowingStream<AppLogLine, Error> {
        let (stream, continuation) = AsyncThrowingStream<AppLogLine, Error>.makeStream()
        record(.stream(udid: udid, filter: filter)) { continuations[udid] = continuation }
        return stream
    }

    package func emit(_ line: AppLogLine, on udid: String) {
        lock.withLock { continuations[udid] }?.yield(line)
    }

    package func finish(_ udid: String, throwing error: (any Error)?) {
        lock.withLock { continuations[udid] }?.finish(throwing: error)
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
