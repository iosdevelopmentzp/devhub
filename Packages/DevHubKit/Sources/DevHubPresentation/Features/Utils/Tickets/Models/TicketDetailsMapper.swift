import Foundation
import DevHubDomain
import DevHubUI

enum TicketDetailsMapper {
    static let commentLimit = 5

    static func model(for details: TrackerIssueDetails, ticketURL: URL?, now: Date) -> TicketDetailsModel {
        let recentCount = min(details.comments.count, commentLimit)
        let earlier = details.comments.count - recentCount
        return TicketDetailsModel(
            description: details.description.trimmed.isEmpty ? nil : details.description,
            facts: facts(for: details),
            dueTag: TicketRowMapper.dueTag(for: details.dueDate, isDone: details.resolution != nil, now: now),
            labels: details.labels,
            components: details.components,
            fixVersions: details.fixVersions,
            parent: details.parent.map { link(for: $0, ticketURL: ticketURL) },
            subtasks: details.subtasks.map { link(for: $0, ticketURL: ticketURL) },
            links: details.links.map { relation in
                var model = link(for: relation.issue, ticketURL: ticketURL)
                model.relation = relation.relation.isEmpty ? nil : relation.relation
                return model
            },
            attachmentsText: attachmentsText(details.attachments),
            timeText: timeText(original: details.originalEstimateSeconds, spent: details.timeSpentSeconds, remaining: details.remainingEstimateSeconds),
            watchersText: watchersText(count: details.watchers, isWatching: details.isWatching),
            isWatching: details.isWatching == true,
            comments: details.comments.map { comment in
                TicketCommentModel(
                    id: comment.id,
                    author: comment.author.isEmpty ? "Someone" : comment.author,
                    dateText: comment.createdAt?.relativeDescription,
                    body: comment.body
                )
            },
            recentCount: recentCount,
            earlierCommentsTitle: earlier > 0 ? "Show \(CountText.count(earlier, "earlier comment", "earlier comments"))" : nil
        )
    }

    static func link(for issue: TrackerIssueLink, ticketURL: URL?) -> TicketLinkModel {
        TicketLinkModel(
            id: issue.key,
            key: issue.key,
            summary: issue.summary,
            statusTag: TagModel(issue.status.isEmpty ? "Unknown" : issue.status, tint: TicketRowMapper.statusTint(issue.statusCategory), hint: "Status in the tracker"),
            relation: nil,
            url: url(for: issue.key, from: ticketURL)
        )
    }

    static func url(for key: String, from ticketURL: URL?) -> URL? {
        guard let ticketURL, ticketURL.pathComponents.count > 1 else { return nil }
        return ticketURL.deletingLastPathComponent().appendingPathComponent(key)
    }

    static func timeText(original: Int?, spent: Int?, remaining: Int?) -> String? {
        var parts: [String] = []
        if let spent {
            let estimate = original.map { " of \(WorkTime.text(seconds: $0))" } ?? ""
            parts.append("Logged \(WorkTime.text(seconds: spent))\(estimate)")
        } else if let original {
            parts.append("Estimate \(WorkTime.text(seconds: original))")
        }
        if let remaining {
            parts.append("\(WorkTime.text(seconds: remaining)) left")
        }
        guard parts.isEmpty == false else { return nil }
        return parts.joined(separator: ", ")
    }

    static func watchersText(count: Int?, isWatching: Bool?) -> String? {
        guard let count else { return nil }
        let text = CountText.count(count, "watcher", "watchers")
        return isWatching == true ? "\(text), you watch this ticket" : text
    }

    static func attachmentsText(_ names: [String]) -> String? {
        guard names.isEmpty == false else { return nil }
        return "\(CountText.count(names.count, "file", "files")): \(names.joined(separator: ", "))"
    }

    private static func facts(for details: TrackerIssueDetails) -> [String] {
        var facts: [String] = []
        if let reporter = details.reporter, reporter.isEmpty == false {
            facts.append("Reported by \(reporter)")
        }
        if let created = details.createdAt {
            facts.append("created \(created.relativeDescription)")
        }
        if let resolution = details.resolution, resolution.isEmpty == false {
            facts.append("Resolved: \(resolution)")
        }
        return facts
    }
}
