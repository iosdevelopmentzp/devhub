import Foundation
import DevHubDomain

struct TicketSectionModel: Identifiable, Equatable {
    let id: IssueStatusCategory
    var title: String
    var issues: [TrackerIssue]

    static let preview = TicketSectionModel(id: .inProgress, title: "In progress", issues: [])
}
