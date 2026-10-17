import Foundation
import DevHubDomain
import DevHubUI

struct ClaudeSessionSection: Identifiable, Equatable {
    var title: String
    var rows: [ClaudeSessionRowModel]

    var id: String { title }
}
