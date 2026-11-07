import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct CIWatchStoreTests {
    private let harness = StoreHarness()
    private let workflowID = "11111111-2222-3333-4444-555555555555"
    private let approval = CIJob(id: "job-approve", name: "approve-release", status: .manual, isApproval: true)

    private var store: CIWatchStore {
        harness.ciWatch
    }

    private var notifiedKey: String {
        PullRequestsPreferenceKeys.ciNotified(projectID: harness.session.selectedProjectID)
    }

    private func script(approval status: CheckStatus, checks: CheckStatus = .pending, author: String = "me") async {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]
        let request = PullRequestSummaryFixture.request(iid: 7, source: "feature/mine", state: .opened, author: author, pipeline: PipelineInfo(status: checks, webURL: nil, updatedAt: nil))
        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: [request], totalCount: 1))
        harness.spies.codeHost.detailsResult = .success(PullRequestDetails(description: "", threads: [], jobs: [
            PipelineJob(name: "ci/circleci: approve-release", stage: nil, webURL: URL(string: "https://app.circleci.example.com/workflow/\(workflowID)/job/22222222-3333-4444-5555-666666666666"), id: nil, status: checks, ciWorkflowID: workflowID),
        ]))
        harness.spies.ci.workflowResult = .success(CIWorkflow(id: workflowID, name: "build-and-test", status: .running, runID: "run-1", jobs: [
            CIJob(id: "job-unit", name: "unit-tests", status: .success, isApproval: false),
            CIJob(id: approval.id, name: approval.name, status: status, isApproval: true),
        ]))
        await harness.openPullRequests.refresh()
    }

    private var workflowReads: Int {
        harness.spies.ci.calls.filter {
            guard case .workflow = $0 else { return false }
            return true
        }.count
    }

    @Test func aJobOnHoldIsListedAndReportedOnce() async throws {
        await script(approval: .manual)

        await store.checkAll()
        await store.checkAll()

        #expect(store.onHold == [7: [approval]])
        #expect(store.onHoldJobNames == [7: ["approve-release"]])
        #expect(workflowReads == 2)
        #expect(harness.activityTitles.filter { $0 == "approve-release of #7 waits for your approval" }.count == 1)
        #expect(harness.lastActivity?.kind == .requestApprovals)
        #expect(harness.lastActivity?.target == .pullRequest(iid: 7))
        try await waitUntil { harness.spies.notifications.posted.isEmpty == false }
        #expect(harness.spies.notifications.posted == [.post(title: "approve-release of #7 waits for your approval", body: "Approve it from the checks of the pull request in DevHub", target: .pullRequest(iid: 7))])
        #expect(harness.store.data(forKey: notifiedKey) != nil)
    }

    @Test func aReportedJobStaysQuietAfterARestart() async throws {
        await script(approval: .manual)
        await store.checkAll()
        try await waitUntil { harness.spies.notifications.posted.count == 1 }

        let again = StoreHarness(store: harness.store)
        again.spies.git.webURLResult = harness.spies.git.webURLResult
        again.spies.tools.existingFiles = harness.spies.tools.existingFiles
        again.spies.codeHost.openRequestsResult = harness.spies.codeHost.openRequestsResult
        again.spies.codeHost.detailsResult = harness.spies.codeHost.detailsResult
        again.spies.ci.workflowResult = harness.spies.ci.workflowResult
        await again.openPullRequests.refresh()
        await again.ciWatch.checkAll()
        await again.settle()

        #expect(again.ciWatch.onHold == [7: [approval]])
        #expect(again.activityTitles.contains("approve-release of #7 waits for your approval") == false)
        #expect(again.spies.notifications.posted.isEmpty)
    }

    @Test func anApprovedJobLeavesTheListWhenTheChecksChange() async throws {
        await script(approval: .manual)
        await store.checkAll()
        #expect(store.onHold[7] == [approval])

        await script(approval: .success)
        harness.events.post(.pullRequestChecksChanged(iid: 7))

        try await waitUntil { store.onHold[7] == nil }
    }

    @Test func aRequestWithFinishedChecksIsNotRead() async {
        await script(approval: .manual, checks: .success)

        await store.checkAll()

        #expect(store.onHold.isEmpty)
        #expect(workflowReads == 0)
        #expect(harness.spies.codeHost.calls.contains { call in
            guard case .details = call else { return false }
            return true
        } == false)
    }

    @Test func anotherAuthorsRequestIsNotWatched() async {
        await script(approval: .manual, author: "sam")

        await store.checkAll()

        #expect(store.onHold.isEmpty)
        #expect(workflowReads == 0)
    }

    @Test func aRequestThatLeftTheListIsForgotten() async {
        await script(approval: .manual)
        await store.checkAll()
        #expect(store.onHold[7] == [approval])

        harness.spies.codeHost.openRequestsResult = .success(PullRequestList(username: "me", requests: [], totalCount: 0))
        await harness.openPullRequests.refresh()
        await store.checkAll()

        #expect(store.onHold.isEmpty)
        #expect(harness.store.data(forKey: notifiedKey) == nil)
    }

    @Test func aFailureIsLoggedOncePerMessage() async {
        await script(approval: .manual)
        harness.spies.ci.workflowResult = .failure(CIError.notLoggedIn)

        await store.checkAll()
        await store.checkAll()

        #expect(store.onHold.isEmpty)
        #expect(harness.activityTitles.filter { $0 == "Cannot check the CircleCI approvals of #7" }.count == 1)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func pollingChecksTheOpenRequests() async throws {
        await script(approval: .manual)

        store.startPolling()

        try await waitUntil { store.onHold[7] == [approval] }
    }

    @Test func theListIsRereadWhenTheRequestsChange() async throws {
        await script(approval: .manual)
        _ = store

        harness.events.post(.pullRequestsChanged)

        try await waitUntil { store.onHold[7] == [approval] }
    }
}
