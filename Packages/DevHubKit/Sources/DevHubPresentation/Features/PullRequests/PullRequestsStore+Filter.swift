import Foundation
import DevHubDomain

extension PullRequestsStore {
    var visible: [PullRequestSummary] {
        PullRequestFilterPolicy.apply(filter, to: scopedRequests)
    }

    var filterOptions: PullRequestFilterOptions {
        PullRequestFilterPolicy.options(in: scopedRequests, keeping: filter)
    }

    func toggleLabel(_ label: String) {
        filter.toggleLabel(label)
    }

    func removeFilter(_ kind: PullRequestFilterChipModel.Kind) {
        switch kind {
        case .targetBranch: filter.targetBranch = nil
        case .label(let label): filter.labels.removeAll { $0 == label }
        case .author: filter.author = nil
        case .assignee: filter.assignee = nil
        case .reviewer: filter.reviewer = nil
        case .onlyConflicts: filter.onlyConflicts = false
        case .onlyReady: filter.onlyReady = false
        }
    }

    func clearFilter() {
        filter = PullRequestFilter()
    }

    private var scopedRequests: [PullRequestSummary] {
        guard scope == .reviewing, let reviewer else { return requests }
        return requests.filter { ReviewQueuePolicy.needsMyReview($0, reviewer: reviewer) }
    }
}
