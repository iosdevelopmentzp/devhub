import Foundation
import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct CheckoutBadgeMapperTests {
    private let worktrees = [WorktreeFixture.main, WorktreeFixture.linked]

    @Test func theMainCheckoutIsQuietAndNamesItsBranch() {
        let model = CheckoutBadgeMapper.buildSource(.main, label: "dev · main checkout", hasWorktree: false, worktrees: worktrees)

        #expect(model.text == "Main checkout · dev")
        #expect(model.icon == "house")
        #expect(model.tint == .secondary)
        #expect(model.isMain)
        #expect(model.hint == "Build source: Main checkout · dev. Click to build the main checkout, a worktree or any branch. A branch without a worktree gets one on the next run.")
    }

    @Test func theMainCheckoutWithoutWorktreesHasNoBranch() {
        let model = CheckoutBadgeMapper.buildSource(.main, label: "ExampleApp · main checkout", hasWorktree: false, worktrees: [])

        #expect(model.text == "Main checkout")
        #expect(model.isMain)
    }

    @Test func aWorktreeSourceIsOrange() {
        let model = CheckoutBadgeMapper.buildSource(.worktree(WorktreeFixture.linked.path), label: "feature/login", hasWorktree: true, worktrees: worktrees)

        #expect(model.text == "Worktree · feature/login")
        #expect(model.icon == "rectangle.stack")
        #expect(model.tint == .orange)
        #expect(model.isMain == false)
    }

    @Test func aBranchWithAWorktreeShowsTheWorktree() {
        let model = CheckoutBadgeMapper.buildSource(.branch("feature/login"), label: "feature/login", hasWorktree: true, worktrees: worktrees)

        #expect(model.text == "Worktree · feature/login")
        #expect(model.icon == "rectangle.stack")
        #expect(model.isMain == false)
    }

    @Test func aBranchWithoutAWorktreeSaysSo() {
        let model = CheckoutBadgeMapper.buildSource(.branch("feature/new"), label: "feature/new · new worktree on run", hasWorktree: false, worktrees: worktrees)

        #expect(model.text == "Branch · feature/new · new worktree on run")
        #expect(model.icon == "arrow.triangle.branch")
        #expect(model.tint == .orange)
        #expect(model.isMain == false)
    }

    @Test func theGitCheckoutNamesTheMainCheckoutOrTheWorktree() {
        let main = CheckoutBadgeMapper.gitCheckout(path: WorktreeFixture.main.path, worktree: WorktreeFixture.main)
        let linked = CheckoutBadgeMapper.gitCheckout(path: WorktreeFixture.linked.path, worktree: WorktreeFixture.linked)

        #expect(main.text == "Main checkout · dev")
        #expect(main.icon == "house")
        #expect(main.isMain)
        #expect(main.tint == .secondary)
        #expect(linked.text == "Worktree · feature/login")
        #expect(linked.icon == "rectangle.stack")
        #expect(linked.isMain == false)
        #expect(linked.tint == .orange)
        #expect(linked.hint == "The actions of this tab run in this checkout: Worktree · feature/login. Click to choose another checkout.")
    }

    @Test func anUnknownCheckoutShowsItsPathAsNotMain() {
        let model = CheckoutBadgeMapper.gitCheckout(path: NSHomeDirectory() + "/Projects/ExampleApp", worktree: nil)

        #expect(model.text == "~/Projects/ExampleApp")
        #expect(model.icon == "folder")
        #expect(model.isMain == false)
        #expect(model.tint == .orange)
    }
}
