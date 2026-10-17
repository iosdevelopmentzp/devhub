import Foundation

package enum ReviewQueuePolicy {

    package static func needsMyReview(_ request: MergeRequestSummary, username: String) -> Bool {
        request.state == .opened
            && request.isDraft == false
            && request.author != username
            && request.approvedBy.contains(username) == false
    }

    package static func count(in requests: [MergeRequestSummary], username: String) -> Int {
        requests.filter { needsMyReview($0, username: username) }.count
    }
}
