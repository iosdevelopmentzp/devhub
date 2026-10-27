import Foundation
import DevHubDomain
import DevHubUI

struct AISessionSection: Identifiable, Equatable {
    var title: String
    var systemImage: String?
    var iconTint: Tint
    var detail: String?
    var rows: [AISessionRowModel]

    var id: String { title }
}
