import DevHubDomain
import Foundation

package final class SpyClaudeUsageRepository: ClaudeUsageRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case fetch
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _fetchResult: Result<ClaudeUsage, any Error> = .success(ClaudeUsage(plan: "", limits: [], updatedAt: Date(timeIntervalSince1970: 0)))

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var fetchResult: Result<ClaudeUsage, any Error> {
        get { lock.withLock { _fetchResult } }
        set { lock.withLock { _fetchResult = newValue } }
    }

    package func fetch() async throws -> ClaudeUsage {
        try record(.fetch) { try _fetchResult.get() }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
