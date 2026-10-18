import DevHubDomain
import Foundation

package final class SpyCopilotUsageRepository: CopilotUsageRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case fetch
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _fetchResult: Result<CopilotUsage?, any Error> = .success(nil)

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var fetchResult: Result<CopilotUsage?, any Error> {
        get { lock.withLock { _fetchResult } }
        set { lock.withLock { _fetchResult = newValue } }
    }

    package func fetch() async throws -> CopilotUsage? {
        try lock.withLock {
            _calls.append(.fetch)
            return try _fetchResult.get()
        }
    }
}
