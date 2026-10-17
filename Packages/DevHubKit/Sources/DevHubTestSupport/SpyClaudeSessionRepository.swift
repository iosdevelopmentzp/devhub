import DevHubDomain
import Foundation

package final class SpyClaudeSessionRepository: ClaudeSessionRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case sessions
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _sessionsResult: [ClaudeSession] = []

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var sessionsResult: [ClaudeSession] {
        get { lock.withLock { _sessionsResult } }
        set { lock.withLock { _sessionsResult = newValue } }
    }

    package func sessions() async -> [ClaudeSession] {
        record(.sessions) { _sessionsResult }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
