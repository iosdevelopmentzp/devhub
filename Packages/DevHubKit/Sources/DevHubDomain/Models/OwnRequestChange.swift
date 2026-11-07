import Foundation

package enum OwnRequestChange: Hashable, Sendable {
    case approved(PullRequestSummary, by: [String])
    case changesRequested(PullRequestSummary, by: [String])
    case checksFailed(PullRequestSummary)
    case checksPassed(PullRequestSummary)
    case newComments(PullRequestSummary, count: Int, by: [String])
    case gone(PullRequestSummary)

    package var request: PullRequestSummary {
        switch self {
        case .approved(let request, _), .changesRequested(let request, _), .checksFailed(let request), .checksPassed(let request), .newComments(let request, _, _), .gone(let request):
            request
        }
    }
}
