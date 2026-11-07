import Foundation
import DevHubDomain

@MainActor
protocol OpenRequestsLookup: AnyObject {
    var requests: [PullRequestSummary] { get }
    var username: String? { get }
    var reviewTeams: [String] { get }
    var reviewQueue: ReviewQueueRule { get }
}

extension OpenRequestsLookup {
    func reviewer(username: String?) -> ReviewerIdentity? {
        username.map { ReviewerIdentity(username: $0, teams: reviewTeams, rule: reviewQueue) }
    }
}
