import Foundation

struct DiskCleanupModel: Equatable {
    var rows: [DiskCleanupRowModel]
    var groups: [DiskCleanupGroupModel]
    var totalText: String?

    var isEmpty: Bool {
        rows.isEmpty && groups.isEmpty
    }
}
