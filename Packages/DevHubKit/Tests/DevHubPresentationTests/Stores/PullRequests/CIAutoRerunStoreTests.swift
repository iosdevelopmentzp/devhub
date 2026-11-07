import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubMocks
@testable import DevHubPresentation

@Suite struct CIAutoRerunStoreTests {
    private let harness = StoreHarness()
    private let workflowID = "11111111-2222-3333-4444-555555555555"

    private var store: CIAutoRerunStore {
        harness.ciAutoRerun
    }

    private var project: CIProject {
        CIProject(checkoutPath: harness.worktrees.mainCheckoutPath, slug: "gh/example/app")
    }

    private var rerunCalls: [SpyCIRepository.Call] {
        harness.spies.ci.calls.filter {
            guard case .rerun = $0 else { return false }
            return true
        }
    }

    private func script(_ status: CheckStatus) {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]
        harness.spies.codeHost.detailsResult = .success(PullRequestDetails(description: "", threads: [], jobs: [
            PipelineJob(name: "ci/circleci: unit-tests", stage: nil, webURL: URL(string: "https://app.circleci.example.com/workflow/\(workflowID)/job/22222222-3333-4444-5555-666666666666"), id: nil, status: status, ciWorkflowID: workflowID),
        ]))
        harness.spies.ci.workflowResult = .success(CIWorkflow(id: workflowID, name: "build-and-test", status: status, runID: "run-1", jobs: [
            CIJob(id: "job-unit", name: "unit-tests", status: status, isApproval: false),
        ]))
        harness.spies.ci.failedTestsResult = .success([CITestResult(className: "LoginTests", name: "testRetry", result: "failure", runTime: 1, message: "boom")])
        harness.spies.ci.flakyTestsResult = .success([CIFlakyTest(className: "LoginTests", name: "testRetry", jobName: "unit-tests", workflowName: "build-and-test", timesFlaked: 3)])
    }

    private var flakyReads: Int {
        harness.spies.ci.calls.filter {
            guard case .flakyTests = $0 else { return false }
            return true
        }.count
    }

    private func seed(_ plan: CIAutoRerunPlan) {
        harness.store.encode([plan], forKey: PullRequestsPreferenceKeys.autoRerun(projectID: harness.session.selectedProjectID))
    }

    @Test func startRunsTheFailedJobsAgainAndKeepsTheFailedRun() async throws {
        script(.failed)

        store.start(7, maxAttempts: 3)
        try await waitUntil { store.plan(for: 7)?.attempts == 1 }

        #expect(rerunCalls == [.rerun(workflowID: workflowID, fromFailed: true, project: project)])
        #expect(store.plan(for: 7)?.handledWorkflowIDs == [workflowID])
        #expect(store.plan(for: 7)?.lastRerunAt != nil)
        #expect(harness.ciHistory.records(for: 7).map(\.id) == [workflowID])
        #expect(harness.ciHistory.records(for: 7).first?.failedTestCount == 1)
        #expect(harness.postedLabels.contains("pullRequestChecksChanged(7)"))
        #expect(harness.activityTitles.contains("Re-run 1 of 3: build-and-test of #7"))
    }

    @Test func aFailureOnATestThatIsNotFlakyStopsThePlan() async {
        script(.failed)
        harness.spies.ci.flakyTestsResult = .success([])
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 1, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(rerunCalls.isEmpty)
        #expect(store.plan(for: 7) == nil)
        #expect(harness.ciHistory.records(for: 7).map(\.id) == [workflowID])
        #expect(harness.lastActivity?.title == "Auto re-run of #7 stopped")
        #expect(harness.lastActivity?.detail == "No re-run: unit-tests failed on a test that is not flaky")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aFailureWithoutTestResultsStopsThePlan() async {
        script(.failed)
        harness.spies.ci.failedTestsResult = .success([])
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(rerunCalls.isEmpty)
        #expect(harness.lastActivity?.detail == "No re-run: unit-tests failed without test results")
    }

    @Test func everyFailureRunsAgainWhenTheModeIsOff() async throws {
        script(.failed)
        harness.spies.ci.flakyTestsResult = .success([])

        store.setOnlyFlaky(false)
        store.start(7, maxAttempts: 3)
        try await waitUntil { store.plan(for: 7)?.attempts == 1 }

        #expect(store.plan(for: 7)?.onlyFlaky == false)
        #expect(rerunCalls.count == 1)
        #expect(flakyReads == 0)
        #expect(harness.activityTitles.contains("Auto re-run: every failure"))
    }

    @Test func theModeIsSavedPerProjectAndReadBack() {
        store.setOnlyFlaky(false)
        #expect(harness.store.string(forKey: PullRequestsPreferenceKeys.autoRerunOnlyFlaky(projectID: harness.session.selectedProjectID)) == "any")

        let reopened = StoreHarness(projects: [ProjectSample.app], store: harness.store)
        #expect(reopened.ciAutoRerun.onlyFlaky == false)

        reopened.ciAutoRerun.setOnlyFlaky(true)
        #expect(StoreHarness(projects: [ProjectSample.app], store: harness.store).ciAutoRerun.onlyFlaky)
    }

    @Test func theFlakyListIsReadOnceForTenMinutes() async {
        script(.failed)
        harness.store.encode([
            CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil),
            CIAutoRerunPlan(iid: 9, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil),
        ], forKey: PullRequestsPreferenceKeys.autoRerun(projectID: harness.session.selectedProjectID))

        await store.check(7)
        await store.check(9)

        #expect(rerunCalls.count == 2)
        #expect(flakyReads == 1)
    }

    @Test func aFlakyListThatCannotBeReadCountsAsEmpty() async {
        script(.failed)
        harness.spies.ci.flakyTestsResult = .failure(CIError.command("insights off"))
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(store.plan(for: 7) == nil)
        #expect(harness.activityTitles.contains("Cannot read the flaky tests of CircleCI"))
        #expect(harness.lastActivity?.detail == "No re-run: unit-tests failed on a test that is not flaky")
    }

    @Test func aPassingWorkflowEndsThePlan() async throws {
        script(.success)

        store.start(7, maxAttempts: 3)
        try await waitUntil { store.plan(for: 7) == nil }

        #expect(rerunCalls.isEmpty)
        #expect(harness.lastActivity?.title == "Checks of #7 passed")
        #expect(harness.lastActivity?.detail == "No re-run was needed")
        #expect(harness.lastActivity?.outcome == .success)
    }

    @Test func aFailureAfterTheLastAttemptGivesUp() async {
        script(.failed)
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 3, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(rerunCalls.isEmpty)
        #expect(store.plan(for: 7) == nil)
        #expect(harness.lastActivity?.title == "Auto re-run of #7 gave up")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func aCancelledWorkflowStopsThePlan() async {
        script(.canceled)
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 1, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(store.plan(for: 7) == nil)
        #expect(harness.lastActivity?.title == "Auto re-run of #7 stopped")
    }

    @Test func aWorkflowThatRanAgainWaitsForItsNewRun() async {
        script(.failed)
        let plan = CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 1, handledWorkflowIDs: [workflowID], lastRerunAt: .now)
        seed(plan)

        await store.check(7)

        #expect(rerunCalls.isEmpty)
        #expect(store.plan(for: 7) == plan)
    }

    @Test func aRunningWorkflowWaits() async {
        script(.running)
        let plan = CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil)
        seed(plan)

        await store.check(7)

        #expect(rerunCalls.isEmpty)
        #expect(store.plan(for: 7) == plan)
    }

    @Test func aFailedRerunKeepsTheAttempt() async {
        script(.failed)
        harness.spies.ci.actionError = TestError.scripted("offline")
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(store.plan(for: 7)?.attempts == 0)
        #expect(harness.postedLabels.contains("pullRequestChecksChanged(7)") == false)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func theSameReadErrorIsLoggedOnce() async {
        script(.failed)
        harness.spies.ci.workflowResult = .failure(CIError.notLoggedIn)
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)
        await store.check(7)

        #expect(harness.activityTitles.filter { $0 == "Auto re-run of #7 cannot read the checks" }.count == 1)
    }

    @Test func stopRemovesTheSavedPlan() {
        script(.running)
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        store.stop(7)

        #expect(store.plan(for: 7) == nil)
        #expect(harness.store.data(forKey: PullRequestsPreferenceKeys.autoRerun(projectID: harness.session.selectedProjectID)) == nil)
    }

    @Test func aPlanIsSavedAndReadBack() {
        script(.running)

        store.start(7, maxAttempts: 5)
        let reopened = StoreHarness(projects: [ProjectSample.app], store: harness.store)

        #expect(reopened.ciAutoRerun.plan(for: 7)?.maxAttempts == 5)
        #expect(reopened.ciAutoRerun.plan(for: 7)?.attempts == 0)
    }

    @Test func noCircleCIConfigMeansNoAction() async {
        script(.failed)
        harness.spies.tools.existingFiles = []
        seed(CIAutoRerunPlan(iid: 7, maxAttempts: 3, attempts: 0, handledWorkflowIDs: [], lastRerunAt: nil))

        await store.check(7)

        #expect(harness.spies.ci.calls.isEmpty)
        #expect(store.plan(for: 7)?.attempts == 0)
    }
}
