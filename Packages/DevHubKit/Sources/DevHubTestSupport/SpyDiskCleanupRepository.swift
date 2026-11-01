import DevHubDomain
import Foundation

package final class SpyDiskCleanupRepository: DiskCleanupRepository, @unchecked Sendable {
    package enum Call: Hashable {
        case items
        case size(DiskCleanupItem.ID)
        case clean(DiskCleanupItem.ID)
    }

    private let lock = NSLock()
    private var _calls: [Call] = []
    private var _itemsResult: Result<[DiskCleanupItem], any Error> = .success([])
    private var _sizes: [DiskCleanupItem.ID: Int64] = [:]
    private var _cleanError: (any Error)?

    package init() {}

    package var calls: [Call] {
        lock.withLock { _calls }
    }

    package var itemsResult: Result<[DiskCleanupItem], any Error> {
        get { lock.withLock { _itemsResult } }
        set { lock.withLock { _itemsResult = newValue } }
    }

    package var sizes: [DiskCleanupItem.ID: Int64] {
        get { lock.withLock { _sizes } }
        set { lock.withLock { _sizes = newValue } }
    }

    package var cleanError: (any Error)? {
        get { lock.withLock { _cleanError } }
        set { lock.withLock { _cleanError = newValue } }
    }

    package func items() async throws -> [DiskCleanupItem] {
        try lock.withLock {
            _calls.append(.items)
            return try _itemsResult.get()
        }
    }

    package func size(of item: DiskCleanupItem) async -> Int64? {
        lock.withLock {
            _calls.append(.size(item.id))
            return item.size ?? _sizes[item.id]
        }
    }

    package func clean(_ item: DiskCleanupItem) async throws {
        try lock.withLock {
            _calls.append(.clean(item.id))
            if let _cleanError { throw _cleanError }
        }
    }
}
