import Foundation

package protocol DiskCleanupRepository: Sendable {
    func items() async throws -> [DiskCleanupItem]
    func size(of item: DiskCleanupItem) async -> Int64?
    func clean(_ item: DiskCleanupItem) async throws
}
