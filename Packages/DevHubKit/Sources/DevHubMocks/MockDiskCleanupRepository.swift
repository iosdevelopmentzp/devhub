import Foundation
import DevHubDomain

struct MockDiskCleanupRepository: DiskCleanupRepository {
    func items() async throws -> [DiskCleanupItem] {
        try? await Task.sleep(for: .milliseconds(200))
        return MockData.diskCleanupItems
    }

    func size(of item: DiskCleanupItem) async -> Int64? {
        try? await Task.sleep(for: .milliseconds(300))
        return item.size ?? MockData.diskCleanupSizes[item.id]
    }

    func clean(_ item: DiskCleanupItem) async throws {
        try? await Task.sleep(for: .milliseconds(500))
    }
}
