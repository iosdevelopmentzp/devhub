import Foundation

package enum CIWatchPolicy {

    package static func watchedRequests(in requests: [PullRequestSummary], username: String?) -> [Int] {
        guard let username else { return [] }
        return requests
            .filter { $0.author == username && $0.state == .opened && waitsForChecks($0.pipeline?.status) }
            .map(\.iid)
            .sorted()
    }

    package static func jobsOnHold(in workflows: [CIWorkflow]) -> [CIJob] {
        workflows.flatMap(\.jobs).filter { $0.isApproval && $0.status == .manual }
    }

    private static func waitsForChecks(_ status: CheckStatus?) -> Bool {
        guard let status else { return false }
        return PipelineStatePolicy.isActive(status) || status == .manual
    }
}
