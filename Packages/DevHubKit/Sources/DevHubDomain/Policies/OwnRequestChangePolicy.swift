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
            let requesters = request.changesRequestedBy.filter { $0 != username && old.changesRequestedBy.contains($0) == false }
            if requesters.isEmpty == false {
                changes.append(.changesRequested(request, by: requesters))
            }
            if request.pipeline?.status == .failed, old.pipeline?.status != .failed {
                changes.append(.checksFailed(request))
            }
            if let comments = newComments(of: request, since: old, username: username) {
                changes.append(comments)
            }
        }
        let gone = before.values
            .filter { old in now.contains { $0.iid == old.iid } == false }
            .sorted { $0.iid < $1.iid }
        return changes + gone.map(OwnRequestChange.gone)
    }

    private static func newComments(of request: PullRequestSummary, since old: PullRequestSummary, username: String) -> OwnRequestChange? {
        let added = request.commentCount - old.commentCount
        guard added > 0 else { return nil }
        guard request.recentComments.isEmpty == false || old.recentComments.isEmpty == false else {
            return .newComments(request, count: added, by: [])
        }
        let known = Set(old.recentComments.map(\.id))
        let fresh = request.recentComments.filter { known.contains($0.id) == false && $0.author != username }
        guard fresh.isEmpty == false else { return nil }
        var authors: [String] = []
        for comment in fresh where authors.contains(comment.author) == false {
            authors.append(comment.author)
        }
        return .newComments(request, count: fresh.count, by: authors)
    }
}
