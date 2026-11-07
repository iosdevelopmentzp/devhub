import Foundation
import Testing
@testable import DevHubDomain

@Suite struct CIWatchPolicyTests {
    private func request(_ iid: Int, author: String, state: PullRequestState = .opened, pipeline: CheckStatus? = .running) -> PullRequestSummary {
        PullRequestSummary(
            iid: iid,
            title: "ABC-\(iid)",
            state: state,
            isDraft: false,
            webURL: nil,
            author: author,
            sourceBranch: "feature/ABC-\(iid)",
            targetBranch: "main",
            hasConflicts: false,
            detailedStatus: nil,
            commentCount: 0,
            updatedAt: nil,
            pipeline: pipeline.map { PipelineInfo(status: $0, webURL: nil, updatedAt: nil) },
            approvedBy: [],
            labels: []
        )
    }

    @Test func onlyOwnOpenRequestsWithUnfinishedChecksAreWatched() {
        let requests = [
            request(9, author: "alex", pipeline: .pending),
            request(3, author: "alex", pipeline: .manual),
            request(4, author: "alex", pipeline: .success),
            request(5, author: "alex", pipeline: .failed),
            request(6, author: "alex", pipeline: nil),
            request(7, author: "sam", pipeline: .running),
            request(8, author: "alex", state: .merged, pipeline: .running),
        ]

        #expect(CIWatchPolicy.watchedRequests(in: requests, username: "alex") == [3, 9])
        #expect(CIWatchPolicy.watchedRequests(in: requests, username: nil).isEmpty)
    }

    @Test func jobsOnHoldAreTheApprovalJobsThatWait() {
        let approve = CIJob(id: "job-approve", name: "approve-release", status: .manual, isApproval: true)
        let workflows = [
            CIWorkflow(id: "w1", name: "build", status: .running, runID: nil, jobs: [
                CIJob(id: "job-unit", name: "unit-tests", status: .manual, isApproval: false),
                approve,
            ]),
            CIWorkflow(id: "w2", name: "deploy", status: .success, runID: nil, jobs: [
                CIJob(id: "job-approved", name: "approve-deploy", status: .success, isApproval: true),
            ]),
        ]

        #expect(CIWatchPolicy.jobsOnHold(in: workflows) == [approve])
    }
}
