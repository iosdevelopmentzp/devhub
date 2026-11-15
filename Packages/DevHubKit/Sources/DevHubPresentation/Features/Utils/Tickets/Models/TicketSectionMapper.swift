import Foundation
import DevHubDomain

enum TicketSectionMapper {
    static let order: [IssueStatusCategory] = [.inProgress, .toDo, .unknown, .done]
    static let starredID = "starred"
    static let noType = "Other"
    static let unassigned = "Unassigned"
    static let noPriority = "No priority"

    static func sections(for issues: [TrackerIssue], grouping: TicketGrouping, starred: [String]) -> [TicketSectionModel] {
        let pinned = issues.filter { starred.contains($0.key) }
        guard pinned.isEmpty == false else { return grouped(issues, by: grouping) }
        let rest = issues.filter { starred.contains($0.key) == false }
        return [TicketSectionModel(id: starredID, title: TicketsText.starredSectionTitle, issues: pinned)] + grouped(rest, by: grouping)
    }

    static func title(for category: IssueStatusCategory) -> String {
        switch category {
        case .inProgress: "In progress"
        case .toDo: "To do"
        case .done: "Done"
        case .unknown: "Other"
        }
    }

    static func priorityRank(_ priority: String) -> Int {
        switch priority.lowercased() {
        case "highest", "blocker", "critical": 0
        case "high", "major": 1
        case "medium", "normal": 2
        case "low", "minor": 3
        case "lowest", "trivial": 4
        case noPriority.lowercased(): 6
        default: 5
        }
    }

    private static func grouped(_ issues: [TrackerIssue], by grouping: TicketGrouping) -> [TicketSectionModel] {
        switch grouping {
        case .status:
            return order.compactMap { category in
                let matching = issues.filter { $0.statusCategory == category }
                guard matching.isEmpty == false else { return nil }
                return TicketSectionModel(id: "status:\(category.rawValue)", title: title(for: category), issues: matching)
            }
        case .type:
            let groups = groups(of: issues) { $0.type.isEmpty ? noType : $0.type }
            return sections(groups.sorted { $0.issues.count != $1.issues.count ? $0.issues.count > $1.issues.count : isOrdered($0.name, $1.name) }, grouping: grouping)
        case .assignee:
            let groups = groups(of: issues) { $0.assignee ?? unassigned }
            return sections(groups.sorted { ($0.name == unassigned ? 1 : 0, $0.name) < ($1.name == unassigned ? 1 : 0, $1.name) }, grouping: grouping)
        case .priority:
            let groups = groups(of: issues) { $0.priority ?? noPriority }
            return sections(groups.sorted { (priorityRank($0.name), $0.name) < (priorityRank($1.name), $1.name) }, grouping: grouping)
        }
    }

    private static func groups(of issues: [TrackerIssue], name: (TrackerIssue) -> String) -> [(name: String, issues: [TrackerIssue])] {
        var names: [String] = []
        var buckets: [String: [TrackerIssue]] = [:]
        for issue in issues {
            let key = name(issue)
            if buckets[key] == nil {
                names.append(key)
            }
            buckets[key, default: []].append(issue)
        }
        return names.map { ($0, buckets[$0] ?? []) }
    }

    private static func sections(_ groups: [(name: String, issues: [TrackerIssue])], grouping: TicketGrouping) -> [TicketSectionModel] {
        groups.map { TicketSectionModel(id: "\(grouping.rawValue):\($0.name)", title: $0.name, issues: $0.issues) }
    }

    private static func isOrdered(_ first: String, _ second: String) -> Bool {
        first.localizedStandardCompare(second) == .orderedAscending
    }
}
