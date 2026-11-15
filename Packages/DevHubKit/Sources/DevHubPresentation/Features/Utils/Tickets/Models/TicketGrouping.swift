import Foundation

enum TicketGrouping: String, CaseIterable, Hashable {
    case status
    case type
    case assignee
    case priority

    var title: String {
        switch self {
        case .status: "Status"
        case .type: "Type"
        case .assignee: "Assignee"
        case .priority: "Priority"
        }
    }
}
