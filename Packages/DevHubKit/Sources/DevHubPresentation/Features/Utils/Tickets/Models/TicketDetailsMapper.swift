import Foundation
import DevHubDomain
import DevHubUI

enum TicketDetailsMapper {
    static let commentLimit = 5

    static func model(for details: TrackerIssueDetails) -> TicketDetailsModel {
        let shown = Array(details.comments.suffix(commentLimit))
        let earlier = details.comments.count - shown.count
        return TicketDetailsModel(
            description: details.description.trimmed.isEmpty ? nil : details.description,
            facts: facts(for: details),
            labels: details.labels,
            components: details.components,
            parent: details.parent.map(link(for:)),
            subtasks: details.subtasks.map(link(for:)),
            comments: shown.map { comment in
                TicketCommentModel(
                    id: comment.id,
                    author: comment.author.isEmpty ? "Someone" : comment.author,
                    dateText: comment.createdAt?.relativeDescription,
                    body: comment.body
                )
            },
            earlierCommentsText: earlier > 0 ? "\(CountText.count(earlier, "earlier comment", "earlier comments")) in the browser" : nil
        )
    }

    static func link(for issue: TrackerIssueLink) -> TicketLinkModel {
        TicketLinkModel(
            id: issue.key,
            key: issue.key,
            summary: issue.summary,
            statusTag: TagModel(issue.status.isEmpty ? "Unknown" : issue.status, tint: TicketRowMapper.statusTint(issue.statusCategory), hint: "Status in the tracker")
        )
    }

    private static func facts(for details: TrackerIssueDetails) -> [String] {
        var facts: [String] = []
        if let reporter = details.reporter, reporter.isEmpty == false {
            facts.append("Reported by \(reporter)")
        }
        if let created = details.createdAt {
            facts.append("created \(created.relativeDescription)")
        }
        return facts
    }
}
