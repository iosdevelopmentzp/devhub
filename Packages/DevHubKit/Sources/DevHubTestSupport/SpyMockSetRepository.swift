import DevHubDomain
import Foundation

package final class SpyMockSetRepository: MockSetRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case list(project: String)
        case save(MockSet, project: String)
        case delete(id: MockSet.ID, project: String)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _listResult: Result<[MockSet], any Error> = .success([])
    private var _saveError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var listResult: Result<[MockSet], any Error> {
        get { lock.withLock { _listResult } }
        set { lock.withLock { _listResult = newValue } }
    }

    package var saveError: (any Error)? {
        get { lock.withLock { _saveError } }
        set { lock.withLock { _saveError = newValue } }
    }

    package var savedSets: [MockSet] {
        calls.compactMap { call in
            guard case .save(let set, _) = call else { return nil }
            return set
        }
    }

    package func list(project: String) async throws -> [MockSet] {
        try lock.withLock {
            _calls.append(.list(project: project))
            return try _listResult.get()
        }
    }

    package func save(_ set: MockSet, project: String) async throws {
        let error = lock.withLock {
            _calls.append(.save(set, project: project))
            return _saveError
        }
        if let error { throw error }
    }

    package func delete(id: MockSet.ID, project: String) async throws {
        lock.withLock { _calls.append(.delete(id: id, project: project)) }
    }
}
