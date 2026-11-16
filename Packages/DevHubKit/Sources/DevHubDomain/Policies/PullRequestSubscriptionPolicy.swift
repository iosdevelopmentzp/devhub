import Foundation

package enum PullRequestSubscriptionPolicy {
    package static func isSubscribed(_ request: PullRequestSummary, changes: [Int: Bool]) -> Bool? {
        changes[request.iid] ?? request.isSubscribed
    }

    package static func canChange(_ request: PullRequestSummary, username: String?) -> Bool {
        guard let username else { return false }
        return request.state == .opened && request.author != username
    }

    package static func othersToUnsubscribe(_ requests: [PullRequestSummary], username: String?, changes: [Int: Bool]) -> [PullRequestSummary] {
        requests
            .filter { canChange($0, username: username) && isSubscribed($0, changes: changes) == true }
            .sorted { $0.iid < $1.iid }
    }

    package static func toSubscribeAgain(_ requests: [PullRequestSummary], unsubscribed: Set<Int>, username: String?, changes: [Int: Bool]) -> [PullRequestSummary] {
        requests
            .filter { unsubscribed.contains($0.iid) && canChange($0, username: username) && isSubscribed($0, changes: changes) == false }
            .sorted { $0.iid < $1.iid }
    }
}
