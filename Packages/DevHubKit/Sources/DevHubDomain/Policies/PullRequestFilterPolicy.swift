import Foundation

package enum PullRequestFilterPolicy {

    package static func apply(_ filter: PullRequestFilter, to requests: [PullRequestSummary]) -> [PullRequestSummary] {
        requests.filter { request in
            if let target = filter.targetBranch, request.targetBranch != target { return false }
            if filter.labels.allSatisfy(request.labels.contains) == false { return false }
            if let author = filter.author, request.author != author { return false }
            if let assignee = filter.assignee, request.assignees.contains(assignee) == false { return false }
            if let reviewer = filter.reviewer, request.reviewers.contains(reviewer) == false { return false }
            if filter.onlyConflicts, request.hasConflicts == false { return false }
            if filter.onlyReady, request.detailedStatus != .mergeable { return false }
            return true
        }
    }

    package static func options(in requests: [PullRequestSummary], keeping filter: PullRequestFilter) -> PullRequestFilterOptions {
        PullRequestFilterOptions(
            targetBranches: sorted(requests.map(\.targetBranch), keeping: filter.targetBranch.map { [$0] } ?? []),
            labels: sorted(requests.flatMap(\.labels), keeping: filter.labels),
            authors: sorted(requests.map(\.author), keeping: filter.author.map { [$0] } ?? []),
            assignees: sorted(requests.flatMap(\.assignees), keeping: filter.assignee.map { [$0] } ?? []),
            reviewers: sorted(requests.flatMap(\.reviewers), keeping: filter.reviewer.map { [$0] } ?? [])
        )
    }

    private static func sorted(_ values: [String], keeping kept: [String]) -> [String] {
        Set(values).union(kept).filter { $0.isEmpty == false }.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }
}
