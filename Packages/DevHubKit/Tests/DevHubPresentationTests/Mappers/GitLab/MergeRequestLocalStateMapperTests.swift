import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct MergeRequestLocalStateMapperTests {
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
        #expect(MergeRequestLocalStateMapper.tag(for: .current)?.text == "current")
        #expect(MergeRequestLocalStateMapper.tag(for: .worktree(path: "/wt/a"))?.text == "worktree")
        #expect(MergeRequestLocalStateMapper.tag(for: .local)?.tint == .teal)
        #expect(MergeRequestLocalStateMapper.tag(for: .none) == nil)
    }

    private func state(_ branch: String, current: String?, path: String?, local: Set<String> = []) -> MergeRequestLocalState {
        MergeRequestLocalStateMapper.state(for: branch, currentBranch: current, localBranches: local, checkoutPath: path, mainCheckoutPath: "/repo")
    }
}
