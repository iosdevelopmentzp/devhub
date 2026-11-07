import Foundation
import DevHubDomain

@MainActor
protocol OpenRequestsLookup: AnyObject {
    var requests: [PullRequestSummary] { get }
    var username: String? { get }
}
