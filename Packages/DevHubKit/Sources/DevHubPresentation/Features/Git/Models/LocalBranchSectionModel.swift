import Foundation
import DevHubDomain
import DevHubUI

struct LocalBranchSectionModel: Identifiable, Equatable {
    enum Kind: String {
        case checkedOut
        case active
        case merged
    }

    let id: Kind
    var title: String
    var detail: String
    var rows: [LocalBranchRowModel]

    static let preview = LocalBranchSectionModel(id: .active, title: "Active", detail: "1", rows: [.preview])
}
