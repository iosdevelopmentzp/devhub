import Foundation
import Testing
import DevHubDomain
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct CIBranchRunsStoreTests {
    private let harness = StoreHarness()
    private let runID = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
    private let workflowID = "11111111-2222-3333-4444-555555555555"

    private var store: CIBranchRunsStore {
        harness.ciBranchRuns
    }

    private var project: CIProject {
        CIProject(checkoutPath: harness.worktrees.mainCheckoutPath, slug: "gh/example/app")
    }

    private func run(_ status: CheckStatus, id: String? = nil, branch: String = "APP-12-login") -> CIRun {
        CIRun(id: id ?? runID, status: status, branch: branch, revision: "abc1234", subject: "ABC-12: Login", createdAt: Date(timeIntervalSince1970: 1_800_000_000))
    }

    private func workflow(_ status: CheckStatus) -> CIWorkflow {
        CIWorkflow(id: workflowID, name: "build-and-test", status: status, runID: runID, jobs: [])
    }

    private func script(_ status: CheckStatus, withBranch: Bool = true) async {
        harness.spies.git.webURLResult = CodeHost.gitHubSample.webURL
        harness.spies.tools.existingFiles = [CIPolicy.circleCIConfigPath(checkoutPath: harness.worktrees.mainCheckoutPath)]
        harness.spies.ci.branchRunsResult = .success([run(status)])
        harness.spies.ci.runWorkflowsResult = .success([workflow(status)])
        if withBranch {
            harness.spies.git.stateResult = .success(GitStateSample.state)
            await harness.git.refresh()
        }
        _ = try? await harness.codeHostRemote.codeHost()
    }

    @Test func refreshReadsTheLatestRunOfTheCurrentBranchAndItsWorkflows() async {
        await script(.failed)

        await store.refresh()

        #expect(store.isAvailable)
        #expect(store.run == run(.failed))
        #expect(store.workflows == [workflow(.failed)])
        #expect(store.error == nil)
        #expect(store.isLoading == false)
        #expect(store.loadedBranch == "APP-12-login")
        #expect(store.slug == "gh/example/app")
        #expect(harness.spies.ci.calls == [.branchRuns(branch: "APP-12-login", limit: 1, project: project), .workflows(runID: runID, project: project)])
    }

    @Test func noProviderOrNoBranchMeansNoCall() async {
        await store.refresh()
        #expect(harness.spies.ci.calls.isEmpty)

        await script(.failed)
        harness.spies.tools.existingFiles = []
        await store.refresh()

        #expect(store.isAvailable == false)
        #expect(harness.spies.ci.calls.isEmpty)
    }

    @Test func refreshIfStaleSkipsABranchReadWithinNinetySeconds() async {
        await script(.success)

        await store.refreshIfStale()
        await store.refreshIfStale()

        #expect(harness.spies.ci.calls.count == 2)
    }

    @Test func aBranchWithoutARunShowsNothingToRerun() async {
        await script(.success)
        harness.spies.ci.branchRunsResult = .success([])

        await store.refresh()

        #expect(store.run == nil)
        #expect(store.workflows.isEmpty)
        #expect(store.loadedBranch == "APP-12-login")
        #expect(harness.spies.ci.calls.count == 1)
    }

    @Test func aReadErrorIsShownAndLoggedOnce() async {
        await script(.failed)
        harness.spies.ci.branchRunsResult = .failure(CIError.notLoggedIn)

        await store.refresh()
        await store.refresh()

        #expect(store.error == CIError.notLoggedIn.localizedDescription)
        #expect(harness.activityTitles.filter { $0 == "Cannot read the CircleCI runs of APP-12-login" }.count == 1)
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func rerunGoesThroughAnOperationAndReadsTheBranchAgain() async throws {
        await script(.failed)
        await store.refresh()

        store.rerun(workflowID, named: "build-and-test")
        try await waitUntil { store.busyWorkflows.isEmpty && harness.activityTitles.contains("Re-ran the failed jobs of build-and-test") }

        #expect(harness.spies.ci.calls.contains(.rerun(workflowID: workflowID, fromFailed: true, project: project)))
        #expect(harness.operations.latest(at: .git)?.status == .succeeded)
        #expect(harness.spies.ci.calls.filter { $0 == .branchRuns(branch: "APP-12-login", limit: 1, project: project) }.count == 2)
    }

    @Test func aFailedCancelIsLogged() async throws {
        await script(.running)
        await store.refresh()
        harness.spies.ci.actionError = TestError.scripted("offline")

        store.cancel(workflowID, named: "build-and-test")
        try await waitUntil { store.busyWorkflows.isEmpty }

        #expect(harness.spies.ci.calls.contains(.cancel(workflowID: workflowID, project: project)))
        #expect(harness.activityTitles.contains("Cancelled build-and-test failed"))
        #expect(harness.operations.latest(at: .git)?.failureMessage != nil)
    }

    @Test func theBaseBranchFailureIsReportedOnceAndShownWhileItLasts() async throws {
        await script(.success)
        harness.spies.ci.branchRunsResult = .success([run(.success, branch: "dev")])

        #expect(await store.checkBase())
        #expect(store.baseFailure == nil)
        #expect(harness.spies.ci.calls.first == .branchRuns(branch: "dev", limit: 1, project: project))

        harness.spies.ci.branchRunsResult = .success([run(.failed, id: "new-run", branch: "dev")])
        harness.spies.ci.runWorkflowsResult = .success([workflow(.failed), CIWorkflow(id: "w2", name: "nightly", status: .success, runID: "new-run", jobs: [])])
        #expect(await store.checkBase())
        #expect(await store.checkBase())

        #expect(store.baseFailure == BaseBranchCIFailure(branch: "dev", workflows: ["build-and-test"], subject: "ABC-12: Login"))
        #expect(harness.activityTitles.filter { $0 == "CI of dev failed: build-and-test" }.count == 1)
        #expect(harness.lastActivity?.kind == .baseBranchChecks)
        #expect(harness.lastActivity?.target == .git)
        try await waitUntil { harness.spies.notifications.posted == [.post(title: "CI of dev failed: build-and-test", body: "ABC-12: Login", target: .git)] }

        harness.spies.ci.branchRunsResult = .success([run(.success, id: "fixed", branch: "dev")])
        #expect(await store.checkBase())
        #expect(store.baseFailure == nil)
    }

    @Test func aBaseBranchThatIsAlreadyFailedAtTheFirstReadIsShownWithoutANotification() async {
        await script(.failed)

        #expect(await store.checkBase())

        #expect(store.baseFailure?.title == "CI of dev failed: build-and-test")
        #expect(harness.activityTitles.contains { $0.hasPrefix("CI of dev failed") } == false)
    }

    @Test func aSetupProblemStopsTheBaseWatch() async {
        await script(.failed)
        harness.spies.ci.branchRunsResult = .failure(CIError.notInstalled)

        let keepsPolling = await store.checkBase()
        _ = await store.checkBase()

        #expect(keepsPolling == false)
        #expect(harness.activityTitles.filter { $0 == "Cannot watch the CI of dev" }.count == 1)
    }

    @Test func pollingStartsWithTheBaseBranch() async throws {
        await script(.success)

        store.startPolling()

        try await waitUntil { store.baseRun != nil }
        #expect(store.baseBranch == "dev")
    }

    @Test func aProjectChangeForgetsEverything() async {
        await script(.failed)
        await store.refresh()
        _ = await store.checkBase()

        harness.events.post(.projectChanged)

        #expect(store.run == nil)
        #expect(store.loadedBranch == nil)
        #expect(store.baseRun == nil)
        #expect(store.baseFailure == nil)
    }
}
