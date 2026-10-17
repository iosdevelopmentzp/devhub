import Foundation
import DevHubDomain
import DevHubUI

struct WorktreeSectionModel: Identifiable, Equatable {
    var title: String
    var rows: [WorktreeRowModel]

    var id: String { title }

    static let preview = WorktreeSectionModel(title: "In progress", rows: [.preview])
}
