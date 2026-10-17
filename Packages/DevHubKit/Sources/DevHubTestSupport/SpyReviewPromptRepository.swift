import DevHubDomain
import Foundation

package final class SpyReviewPromptRepository: ReviewPromptRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case save(String, iid: Int)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _saveResult: Result<String, any Error> = .success("/tmp/prompts/mr.md")

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var saveResult: Result<String, any Error> {
        get { lock.withLock { _saveResult } }
        set { lock.withLock { _saveResult = newValue } }
    }

    package func save(_ prompt: String, iid: Int) async throws -> String {
        try lock.withLock {
            _calls.append(.save(prompt, iid: iid))
            return try _saveResult.get()
        }
    }
}
