import Foundation

package struct PullRequestList: Hashable, Sendable {
    package let username: String
    package let requests: [PullRequestSummary]
    package let totalCount: Int
    package let endCursor: String?
    package let hasNextPage: Bool

    package init(username: String, requests: [PullRequestSummary], totalCount: Int, endCursor: String? = nil, hasNextPage: Bool = false) {
        self.username = username
        self.requests = requests
        self.totalCount = totalCount
        self.endCursor = endCursor
        self.hasNextPage = hasNextPage
    }
}
