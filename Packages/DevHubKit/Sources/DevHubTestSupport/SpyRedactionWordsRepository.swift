import DevHubDomain
import Foundation

package final class SpyRedactionWordsRepository: RedactionWordsRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls = 0
    private var _wordsResult: Result<[RedactionWord], any Error> = .success([])

    package init() {}

    package var calls: Int {
        lock.withLock { _calls }
    }

    package var wordsResult: Result<[RedactionWord], any Error> {
        get { lock.withLock { _wordsResult } }
        set { lock.withLock { _wordsResult = newValue } }
    }

    package func words() async throws -> [RedactionWord] {
        try lock.withLock {
            _calls += 1
            return try _wordsResult.get()
        }
    }
}
