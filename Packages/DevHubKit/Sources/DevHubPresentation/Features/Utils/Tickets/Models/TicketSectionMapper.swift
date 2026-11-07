import Foundation
import DevHubDomain

enum TicketSectionMapper {
    static let order: [IssueStatusCategory] = [.inProgress, .toDo, .unknown, .done]

    static func sections(for issues: [TrackerIssue]) -> [TicketSectionModel] {
        order.compactMap { category in
            let matching = issues.filter { $0.statusCategory == category }
            guard matching.isEmpty == false else { return nil }
            return TicketSectionModel(id: category, title: title(for: category), issues: matching)
        }
    }

    static func title(for category: IssueStatusCategory) -> String {
        switch category {
        case .inProgress: "In progress"
        case .toDo: "To do"
        case .done: "Done"
        case .unknown: "Other"
        }
    }
}
