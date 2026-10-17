import Foundation
import DevHubDomain
import DevHubUI

struct LogLineRowModel: Identifiable, Equatable {
    let id: Int
    var timestamp: String
    var levelTitle: String
    var levelTint: Tint
    var levelOpacity: Double
    var category: String?
    var message: String
    var messageTint: Tint?

    static let preview = LogLineRowModel(
        id: 1,
        timestamp: "14:02:17.384",
        levelTitle: "Error",
        levelTint: .red,
        levelOpacity: 1,
        category: "Networking",
        message: "Request failed: The network connection was lost. (code -1005)",
        messageTint: .red
    )
}
