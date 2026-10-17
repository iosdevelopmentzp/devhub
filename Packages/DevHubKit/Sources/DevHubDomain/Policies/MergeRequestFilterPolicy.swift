import Foundation

package enum MergeRequestFilterPolicy {

    package static func apply(_ filter: MergeRequestFilter, to requests: [MergeRequestSummary]) -> [MergeRequestSummary] {
        requests.filter { request in
            if let target = filter.targetBranch, request.targetBranch != target { return false }
            if let label = filter.label, request.labels.contains(label) == false { return false }
            if filter.onlyConflicts, request.hasConflicts == false { return false }
            if filter.onlyReady, request.detailedStatus != .mergeable { return false }
            return true
        }
    }

    package static func options(in requests: [MergeRequestSummary], keeping filter: MergeRequestFilter) -> MergeRequestFilterOptions {
        let targets = Set(requests.map(\.targetBranch)).union(filter.targetBranch.map { [$0] } ?? [])
        let labels = Set(requests.flatMap(\.labels)).union(filter.label.map { [$0] } ?? [])
        return MergeRequestFilterOptions(targetBranches: targets.sorted(), labels: labels.sorted())
    }
}
