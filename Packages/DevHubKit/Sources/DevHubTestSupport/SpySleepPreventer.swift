import DevHubDomain
import Foundation

package final class SpySleepPreventer: SleepPreventing, @unchecked Sendable {
    package enum Call: Hashable {
        case preventSleep(reason: String)
        case allowSleep
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _preventError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var preventError: (any Error)? {
        get { lock.withLock { _preventError } }
        set { lock.withLock { _preventError = newValue } }
    }

    package func preventSleep(reason: String) throws {
        try lock.withLock {
            _calls.append(.preventSleep(reason: reason))
            if let _preventError { throw _preventError }
        }
    }

    package func allowSleep() {
        lock.withLock { _calls.append(.allowSleep) }
    }
}
