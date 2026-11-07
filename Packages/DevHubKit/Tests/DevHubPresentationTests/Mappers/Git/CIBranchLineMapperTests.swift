import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct CIBranchLineMapperTests {
    private let run = CIRun(id: "run-1", status: .failed, branch: "feature/ABC-123-short-title", revision: "abc1234", subject: "ABC-123: Login", createdAt: Date(timeIntervalSince1970: 1_800_000_000))
    private let base = URL(string: "https://ci.example.com")

    private func model(
        run: CIRun? = nil,
        workflows: [CIWorkflow] = [],
        error: String? = nil,
        isLoading: Bool = false,
        loadedBranch: String? = "feature/ABC-123-short-title",
        branch: String? = "feature/ABC-123-short-title",
        busy: Set<String> = [],
        slug: String? = "gh/example/app",
        base: URL? = nil,
        words: CodeHostWords = .gitHub
    ) -> CIBranchLineModel {
        CIBranchLineMapper.model(run: run, workflows: workflows, error: error, isLoading: isLoading, loadedBranch: loadedBranch, branch: branch, busy: busy, slug: slug, base: base, words: words)
    }

    @Test func theContentFollowsTheReadState() {
        #expect(model(loadedBranch: nil).content == .checking)
        #expect(model(loadedBranch: "other").content == .checking)
        #expect(model(error: "offline", loadedBranch: nil).content == .failure("offline"))
        #expect(model().content == .noRun("No CircleCI run for this branch"))
        #expect(model(isLoading: true).isLoading)
    }

    @Test func aRunGetsOneTagPerWorkflowWithItsActions() throws {
        let workflows = [
            CIWorkflow(id: "w1", name: "build-and-test", status: .failed, runID: "run-1", jobs: []),
            CIWorkflow(id: "w2", name: "deploy", status: .manual, runID: "run-1", jobs: []),
            CIWorkflow(id: "w3", name: "nightly", status: .running, runID: "run-1", jobs: []),
            CIWorkflow(id: "w4", name: "", status: .success, runID: "run-1", jobs: []),
        ]

        guard case .run(let loaded) = model(run: run, workflows: workflows, busy: ["w3"]).content else {
            Issue.record("expected a run")
            return
        }

        #expect(loaded.subject == "ABC-123: Login")
        #expect(loaded.ageText?.isEmpty == false)
        #expect(loaded.workflows.map(\.id) == ["w1", "w2", "w3", "w4"])
        #expect(loaded.workflows[0].tag == TagModel("build-and-test failed", tint: .red, systemImage: "xmark.circle.fill", hint: loaded.workflows[0].tag.hint))
        #expect(loaded.workflows[0].tag.hint?.hasPrefix("CircleCI workflow build-and-test failed, started ") == true)
        #expect(loaded.workflows[0].tag.hint?.hasSuffix(". ABC-123: Login") == true)
        #expect(loaded.workflows[0].canRerun)
        #expect(loaded.workflows[0].canCancel == false)
        #expect(loaded.workflows[0].rerunHint == "Run the failed jobs of build-and-test again (circleci workflow rerun --from-failed)")
        #expect(loaded.workflows[1].tag.text == "deploy on hold")
        #expect(loaded.workflows[1].tag.systemImage == "hand.raised")
        #expect(loaded.workflows[1].canCancel)
        #expect(loaded.workflows[1].canRerun == false)
        #expect(loaded.workflows[2].isBusy)
        #expect(loaded.workflows[2].canCancel)
        #expect(loaded.workflows[2].cancelHint == "Cancel nightly (circleci workflow cancel)")
        #expect(loaded.workflows[3].name == "workflow")
        #expect(loaded.workflows[3].tag.text == "workflow passed")
        #expect(loaded.workflows[3].canRerun == false)
        #expect(loaded.workflows[3].canCancel == false)
    }

    @Test func theLinkNeedsABaseASlugAndABranch() {
        #expect(model(base: base).openURL == URL(string: "https://ci.example.com/pipelines/github/example/app?branch=feature/ABC-123-short-title"))
        #expect(model(base: nil).openURL == nil)
        #expect(model(slug: nil, base: base).openURL == nil)
        #expect(model(branch: nil, base: base).openURL == nil)
    }
}
