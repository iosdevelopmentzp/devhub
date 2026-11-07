import Foundation

package enum ReviewQueuePolicy {

    package static func needsMyReview(_ request: PullRequestSummary, reviewer: ReviewerIdentity) -> Bool {
        let username = reviewer.username
        guard request.state == .opened,
              request.isDraft == false,
              request.author != username,
              request.approvedBy.contains(username) == false
        else { return false }
        switch reviewer.rule {
        case .open: return true
        case .assigned: return isAssigned(request, to: reviewer)
        }
    }

    package static func count(in requests: [PullRequestSummary], reviewer: ReviewerIdentity) -> Int {
        requests.filter { needsMyReview($0, reviewer: reviewer) }.count
    }

    package static func rule(_ value: String?) -> ReviewQueueRule {
        value.flatMap { ReviewQueueRule(rawValue: $0.trimmingCharacters(in: .whitespaces).lowercased()) } ?? .open
    }

    private static func isAssigned(_ request: PullRequestSummary, to reviewer: ReviewerIdentity) -> Bool {
        if request.reviewers.contains(reviewer.username) || request.assignees.contains(reviewer.username) { return true }
        let teams = Set(reviewer.teams.map { $0.lowercased() })
        return request.requestedTeams.contains { teams.contains($0.lowercased()) }
    }
}
