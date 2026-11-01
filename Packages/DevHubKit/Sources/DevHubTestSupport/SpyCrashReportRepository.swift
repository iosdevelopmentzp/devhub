import DevHubDomain
import Foundation

package final class SpyCrashReportRepository: CrashReportRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case reports(since: Date)
        case changes
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _reportsResult: Result<[CrashReport], any Error> = .success([])
    private var _continuations: [AsyncStream<Void>.Continuation] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var reportsResult: Result<[CrashReport], any Error> {
        get { lock.withLock { _reportsResult } }
        set { lock.withLock { _reportsResult = newValue } }
    }

    package func emitChange() {
        lock.withLock { _continuations }.forEach { $0.yield() }
    }

    package func reports(since: Date) async throws -> [CrashReport] {
        try lock.withLock {
            _calls.append(.reports(since: since))
            return try _reportsResult.get()
        }
    }

    package func changes() -> AsyncStream<Void> {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        lock.withLock {
            _calls.append(.changes)
            _continuations.append(continuation)
        }
        return stream
    }
}
