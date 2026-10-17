import Foundation
import DevHubDomain

extension PullRequestsStore {
    var visible: [PullRequestSummary] {
        PullRequestFilterPolicy.apply(filter, to: scopedRequests)
    }

    var filterOptions: PullRequestFilterOptions {
        PullRequestFilterPolicy.options(in: scopedRequests, keeping: filter)
    }

    func removeFilter(_ kind: PullRequestFilterChipModel.Kind) {
        switch kind {
        case .targetBranch: filter.targetBranch = nil
        case .label: filter.label = nil
        case .onlyConflicts: filter.onlyConflicts = false
        case .onlyReady: filter.onlyReady = false
        }
    }

    func clearFilter() {
        filter = PullRequestFilter()
    }

    private var scopedRequests: [PullRequestSummary] {
        guard scope == .reviewing, let username else { return requests }
        return requests.filter { ReviewQueuePolicy.needsMyReview($0, username: username) }
    }
}
