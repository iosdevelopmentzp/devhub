import Foundation
import DevHubDomain
import DevHubUI

struct AISessionSection: Identifiable, Equatable {
    var title: String
    var rows: [AISessionRowModel]

    var id: String { title }
}
