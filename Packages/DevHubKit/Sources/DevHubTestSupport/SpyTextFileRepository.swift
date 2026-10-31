import DevHubDomain
import Foundation

package final class SpyTextFileRepository: TextFileRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case write(String, path: String)
        case writeScratch(String, name: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _writeError: (any Error)?
    private var _scratchResult: Result<String, any Error> = .success("/tmp/scratch/file.txt")

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var writeError: (any Error)? {
        get { lock.withLock { _writeError } }
        set { lock.withLock { _writeError = newValue } }
    }

    package var scratchResult: Result<String, any Error> {
        get { lock.withLock { _scratchResult } }
        set { lock.withLock { _scratchResult = newValue } }
    }

    package func write(_ text: String, to path: String) async throws {
        try lock.withLock {
            _calls.append(.write(text, path: path))
            if let error = _writeError { throw error }
        }
    }

    package func writeScratch(_ text: String, name: String) async throws -> String {
        try lock.withLock {
            _calls.append(.writeScratch(text, name: name))
            return try _scratchResult.get()
        }
    }
}
