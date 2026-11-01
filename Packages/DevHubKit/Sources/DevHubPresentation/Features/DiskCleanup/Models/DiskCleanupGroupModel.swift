import Foundation
import DevHubDomain

struct DiskCleanupGroupModel: Identifiable, Equatable {
    let id: DiskCleanupKind
    var icon: String
    var title: String
    var summary: String
    var rows: [DiskCleanupRowModel]
}
