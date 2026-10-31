import Foundation

package enum OwnRequestChangePolicy {

    package static func changes(from previous: [PullRequestSummary], to current: [PullRequestSummary], username: String) -> [OwnRequestChange] {
        let mineBefore = previous.filter { $0.author == username }
        let before = Dictionary(mineBefore.map { ($0.iid, $0) }, uniquingKeysWith: { first, _ in first })
        let now = current.filter { $0.author == username }.sorted { $0.iid < $1.iid }
        var changes: [OwnRequestChange] = []
        for request in now {
            guard let old = before[request.iid] else { continue }
            let approvers = request.approvedBy.filter { $0 != username && old.approvedBy.contains($0) == false }
            if approvers.isEmpty == false {
                changes.append(.approved(request, by: approvers))
            }
            if request.pipeline?.status == .failed, old.pipeline?.status != .failed {
                changes.append(.checksFailed(request))
            }
            let added = request.commentCount - old.commentCount
            if added > 0 {
                changes.append(.newComments(request, count: added))
            }
        }
        let gone = before.values
            .filter { old in now.contains { $0.iid == old.iid } == false }
            .sorted { $0.iid < $1.iid }
        return changes + gone.map(OwnRequestChange.gone)
    }
}
