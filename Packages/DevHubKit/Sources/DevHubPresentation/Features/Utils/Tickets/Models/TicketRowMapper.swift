import Foundation
import DevHubDomain
import DevHubUI

enum TicketRowMapper {
    static func model(for issue: TrackerIssue, settings: TrackerSettings, isBusy: Bool) -> TicketRowModel {
        let sameStatus = { (status: String) in status.caseInsensitiveCompare(issue.status) == .orderedSame }
        return TicketRowModel(
            id: issue.key,
            key: issue.key,
            summary: issue.summary,
            typeIcon: typeIcon(issue.type),
            typeTint: typeTint(issue.type),
            typeHint: issue.type.isEmpty ? "Ticket" : issue.type,
            statusTag: TagModel(issue.status, tint: statusTint(issue.statusCategory), hint: "Status in the tracker"),
            priorityTag: issue.priority.map { TagModel($0, tint: priorityTint($0), systemImage: "flag", hint: "Priority") },
            assignee: issue.assignee,
            updatedText: issue.updatedAt.map { "updated " + $0.relativeDescription },
            url: issue.url,
            branchName: TrackerBranchPolicy.branchName(for: issue, format: settings.branchFormat),
            startTitle: "Move to \(settings.startStatus)",
            canStart: issue.statusCategory != .done && sameStatus(settings.startStatus) == false,
            moveTargets: settings.statuses.filter { sameStatus($0) == false },
            isBusy: isBusy
        )
    }

    static func typeIcon(_ type: String) -> String {
        let lowered = type.lowercased()
        if lowered.contains("bug") { return "ladybug" }
        if lowered.contains("story") { return "book.closed" }
        if lowered.contains("epic") { return "flag.2.crossed" }
        if lowered.contains("task") { return "checkmark.square" }
        return "doc.text"
    }

    static func typeTint(_ type: String) -> Tint {
        let lowered = type.lowercased()
        if lowered.contains("bug") { return .red }
        if lowered.contains("story") { return .green }
        if lowered.contains("epic") { return .purple }
        if lowered.contains("task") { return .blue }
        return .secondary
    }

    static func statusTint(_ category: IssueStatusCategory) -> Tint {
        switch category {
        case .toDo: .secondary
        case .inProgress: .blue
        case .done: .green
        case .unknown: .gray
        }
    }

    static func priorityTint(_ priority: String) -> Tint {
        switch priority.lowercased() {
        case "highest", "blocker", "critical": .red
        case "high", "major": .orange
        case "low", "lowest", "minor", "trivial": .gray
        default: .secondary
        }
    }
}
