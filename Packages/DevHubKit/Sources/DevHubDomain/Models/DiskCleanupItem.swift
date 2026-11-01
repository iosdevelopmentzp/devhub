import Foundation

package struct DiskCleanupItem: Identifiable, Hashable, Sendable {
    package let id: String
    package var kind: DiskCleanupKind
    package var name: String?
    package var detail: String?
    package var paths: [String]
    package var count: Int
    package var size: Int64?
    package var lastUsed: Date?
    package var runtimeID: String?

    package init(
        id: String,
        kind: DiskCleanupKind,
        name: String? = nil,
        detail: String? = nil,
        paths: [String] = [],
        count: Int = 1,
        size: Int64? = nil,
        lastUsed: Date? = nil,
        runtimeID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.detail = detail
        self.paths = paths
        self.count = count
        self.size = size
        self.lastUsed = lastUsed
        self.runtimeID = runtimeID
    }
}
