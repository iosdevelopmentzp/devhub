import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct NewMergeRequestStoreTests {
    private let harness = StoreHarness()
    private let remote = GitStateSample.webURL

    private var store: NewMergeRequestStore {
        harness.newMergeRequest
    }

    private func prepare() async {
        var state = GitStateSample.state
        state.localBranches = state.localBranches.map { branch in
            var copy = branch
            if copy.name == "APP-12-login" {
                copy.upstream = nil
            }
            return copy
        }
        harness.spies.git.stateResult = .success(state)
        harness.spies.git.webURLResult = remote
        harness.spies.git.subjectsResult = ["Second step", "First step"]
        harness.spies.mergeRequests.labelsResult = .success(["feature", "tech"])
        await harness.git.refresh()
    }

    @Test func openFillsTheFormFromTheCommitsAndLabels() async throws {
        await prepare()

        await store.open(branch: "APP-12-login", origin: .gitLab)

        let draft = try #require(store.draft)
        #expect(draft.origin == .gitLab)
        #expect(draft.targets == ["dev", "feature/new"])
        #expect(draft.targetBranch == "dev")
        #expect(draft.title == "APP-12: Second step")
        #expect(draft.description == "Ticket: APP-12\n\n- First step\n- Second step")
        #expect(draft.availableLabels == ["feature", "tech"])
        #expect(draft.pushPlan == .push(setUpstream: true))
        #expect(draft.isLoading == false)
        #expect(harness.spies.git.calls.contains(.commitSubjects(base: "origin/dev", head: "APP-12-login", path: harness.git.checkoutPath)))
    }

    @Test func aTemplateInTheCheckoutIsTheDescription() async throws {
        await prepare()
        harness.spies.git.templateResult = "## What\n"

        await store.open(branch: "dev", origin: .branch("dev"))

        #expect(store.draft?.description == "## What\n")
        #expect(store.draft?.pushPlan == CreateMergeRequestUseCase.PushPlan.none)
    }

    @Test func labelsThatFailToLoadShowAnError() async {
        await prepare()
        harness.spies.mergeRequests.labelsResult = .failure(MergeRequestError.command("403"))

        await store.open(branch: "dev", origin: .header)

        #expect(store.draft?.availableLabels.isEmpty == true)
        #expect(store.draft?.error == "Cannot read the labels: 403")
    }

    @Test func createSendsTheFormLogsAndCloses() async throws {
        await prepare()
        await store.open(branch: "APP-12-login", origin: .gitLab)
        store.toggleLabel("tech")
        store.draft?.isDraft = true
        let posted = harness.postCount("mergeRequestsChanged")

        let iid = await store.create()

        #expect(iid == 1)
        #expect(store.draft == nil)
        #expect(harness.spies.git.calls.contains(.perform(.push(branch: "APP-12-login", setUpstream: true), path: harness.git.checkoutPath)))
        #expect(harness.spies.mergeRequests.calls.contains(.create(
            NewMergeRequest(sourceBranch: "APP-12-login", targetBranch: "dev", title: "APP-12: Second step", description: "Ticket: APP-12\n\n- First step\n- Second step", labels: ["tech"], isDraft: true, removeSourceBranch: true, squash: false),
            repository: remote
        )))
        #expect(harness.lastActivity?.title == "Created !1")
        #expect(harness.postCount("mergeRequestsChanged") == posted + 1)
    }

    @Test func aFailedCreateKeepsTheFormWithTheError() async {
        await prepare()
        await store.open(branch: "dev", origin: .header)
        harness.spies.mergeRequests.createResult = .failure(MergeRequestError.command("Another open merge request already exists"))

        let iid = await store.create()

        #expect(iid == nil)
        #expect(store.draft?.isCreating == false)
        #expect(store.draft?.error == "Another open merge request already exists")
        #expect(harness.lastActivity?.title == "Cannot create the merge request")
        #expect(harness.lastActivity?.outcome == .failure)
    }

    @Test func toggleCancelAndProjectChange() async {
        await prepare()
        await store.open(branch: "dev", origin: .header)

        store.toggleLabel("feature")
        #expect(store.draft?.labels == ["feature"])
        store.toggleLabel("feature")
        #expect(store.draft?.labels == [])

        store.cancel()
        #expect(store.draft == nil)

        await store.open(branch: "dev", origin: .header)
        harness.events.post(.projectChanged)
        #expect(store.draft == nil)
    }
}
