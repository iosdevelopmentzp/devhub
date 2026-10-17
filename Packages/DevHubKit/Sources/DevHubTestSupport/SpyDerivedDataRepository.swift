import DevHubDomain
import Foundation

package final class SpyDerivedDataRepository: DerivedDataRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case folder(checkout: String)
        case size(URL)
        case remove(URL)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _folderResult: URL? = nil
    private var _sizeResult: Int64? = nil
    private var _removeError: (any Error)? = nil

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var folderResult: URL? {
        get { lock.withLock { _folderResult } }
        set { lock.withLock { _folderResult = newValue } }
    }

    package var sizeResult: Int64? {
        get { lock.withLock { _sizeResult } }
        set { lock.withLock { _sizeResult = newValue } }
    }

    package var removeError: (any Error)? {
        get { lock.withLock { _removeError } }
        set { lock.withLock { _removeError = newValue } }
    }

    package func folder(forCheckout checkout: String) -> URL? {
        record(.folder(checkout: checkout)) { _folderResult }
    }

    package func size(of folder: URL) async -> Int64? {
        record(.size(folder)) { _sizeResult }
    }

    package func remove(_ folder: URL) throws {
        let error = record(.remove(folder)) { _removeError }
        if let error { throw error }
    }

    private func record<Value>(_ call: Call, _ value: () throws -> Value) rethrows -> Value {
        try lock.withLock {
            _calls.append(call)
            return try value()
        }
    }
}
