import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestLocalStateMapperTests {
    @Test func theCurrentBranchOrTheMainCheckoutIsCurrent() {
        #expect(state("feature/a", current: "feature/a", path: nil) == .current)
        #expect(state("feature/a", current: "dev", path: "/repo") == .current)
    }

    @Test func aBranchWithAnotherCheckoutHasAWorktree() {
        #expect(state("feature/a", current: "dev", path: "/wt/a") == .worktree(path: "/wt/a"))
    }

    @Test func aLocalBranchWithoutCheckoutIsLocal() {
        #expect(state("feature/a", current: "dev", path: nil, local: ["feature/a"]) == .local)
        #expect(state("feature/b", current: "dev", path: nil, local: ["feature/a"]) == .none)
    }

    @Test func everyStateButNoneHasATealTag() {
        #expect(PullRequestLocalStateMapper.tag(for: .current)?.text == "current")
        #expect(PullRequestLocalStateMapper.tag(for: .worktree(path: "/wt/a"))?.text == "worktree")
        #expect(PullRequestLocalStateMapper.tag(for: .local)?.tint == .teal)
        #expect(PullRequestLocalStateMapper.tag(for: .none) == nil)
    }

    private func state(_ branch: String, current: String?, path: String?, local: Set<String> = []) -> PullRequestLocalState {
        PullRequestLocalStateMapper.state(for: branch, currentBranch: current, localBranches: local, checkoutPath: path, mainCheckoutPath: "/repo")
    }
}
