import Foundation
import DevHubUI

struct TicketLinkModel: Identifiable, Equatable {
    let id: String
    var key: String
    var summary: String
    var statusTag: TagModel

    static let preview = TicketLinkModel(id: "ABC-100", key: "ABC-100", summary: "Login flow rework", statusTag: TagModel("In Progress", tint: .blue, hint: "Status in the tracker"))
}
