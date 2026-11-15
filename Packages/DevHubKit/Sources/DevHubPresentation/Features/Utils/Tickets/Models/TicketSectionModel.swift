import Foundation
import DevHubDomain

struct TicketSectionModel: Identifiable, Equatable {
    let id: String
    var title: String
    var issues: [TrackerIssue]

    static let preview = TicketSectionModel(id: "status:inProgress", title: "In progress", issues: [])
}
