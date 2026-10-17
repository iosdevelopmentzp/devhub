import DevHubDomain
import DevHubUI
import Foundation
import Testing
import DevHubTestSupport
@testable import DevHubPresentation

@Suite struct GitHeaderMapperTests {
    @Test func cleanTrackedBranch() {
        let model = GitHeaderMapper.model(for: GitSnapshotFixture.clean, baseName: "dev", ticket: .standard)

        #expect(model.branchTitle == "feature/login")
        #expect(model.branchCopyValue == "feature/login")
        #expect(model.head == "a1b2c3d")
        #expect(model.statusTag == TagModel("clean", tint: .green, systemImage: "checkmark", hint: "No uncommitted changes"))
        #expect(model.upstreamTag == TagModel("origin/feature/login", systemImage: "icloud"))
        #expect(model.tags.isEmpty)
        #expect(model.showsMergeRequestLine)
        #expect(model.operationText == nil)
        #expect(model.canContinueOperation == false)
        #expect(model.webBranch == "feature/login")
        #expect(model.newMergeRequestHint == "New merge request for feature/login: title, description and labels here, pushes first when needed")
        #expect(model.branchOnWebHint == "Open feature/login on GitLab")
        #expect(model.forcePushMessage == "Force push feature/login? The remote branch is replaced with your local one. --force-with-lease refuses when someone else pushed meanwhile.")
        #expect(model.rebaseMessage == "Rebase feature/login on origin/dev? 0 new commits come in. Local changes are stashed and restored. After that you need a force push.")
    }

    @Test func detachedHead() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.branch = nil
        snapshot.upstream = nil

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.branchTitle == "detached HEAD")
        #expect(model.branchCopyValue == "a1b2c3d")
        #expect(model.upstreamTag == nil)
        #expect(model.tags.isEmpty)
        #expect(model.showsMergeRequestLine == false)
        #expect(model.webBranch == nil)
        #expect(disabled(model) == [.pull, .push, .forcePush, .rebase])
    }

    @Test func withoutWebURLThereIsNoMergeRequestLine() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.webURL = nil

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.showsMergeRequestLine == false)
        #expect(model.webBranch == nil)
    }

    @Test func dirtyStatusTag() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.changedFiles = 3

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.statusTag == TagModel("3 changed", tint: .orange, systemImage: "pencil", hint: "3 files with changes that are not committed"))
    }

    @Test func syncTagsInOrder() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.ahead = 2
        snapshot.behind = 1
        snapshot.behindBase = 4
        snapshot.aheadOfBase = 5
        snapshot.stashCount = 2

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.tags == [
            TagModel("↑2 to push", tint: .blue, hint: "2 local commits are not on origin/feature/login yet"),
            TagModel("↓1 to pull", tint: .orange, hint: "origin/feature/login has 1 commits you do not have. Pull brings them in."),
            TagModel("4 behind origin/dev", tint: .purple, hint: "origin/dev has 4 commits this branch does not have. Rebase on dev brings them in."),
            TagModel("5 ahead of origin/dev", tint: .teal, hint: "5 commits of this branch are not in origin/dev"),
        ])
        #expect(model.stashTag == TagModel("2 stashed", systemImage: "tray.full", hint: "2 entries in git stash, shared by all worktrees. Click to see them."))
    }

    @Test func theBranchTicketIsAChip() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.branch = "feature/ABC-12-login"

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .linking("https://t.example.com/{key}"))

        #expect(model.ticket?.key == "ABC-12")
        #expect(model.ticket?.url == URL(string: "https://t.example.com/ABC-12"))
        #expect(GitHeaderMapper.model(for: GitSnapshotFixture.clean, baseName: "dev", ticket: .standard).ticket == nil)
    }

    @Test func noStashNoStashTag() {
        #expect(GitHeaderMapper.model(for: GitSnapshotFixture.clean, baseName: "dev", ticket: .standard).stashTag == nil)
    }

    @Test func branchWithoutUpstreamIsNotPushed() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.upstream = nil
        snapshot.ahead = 3

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.tags == [TagModel("not pushed", tint: .orange, systemImage: "icloud.slash", hint: "The branch has no remote branch yet. Push creates it.")])
        #expect(action(.push, in: model)?.hint == "Publish this branch. git push -u <remote> <branch>")
        #expect(action(.pull, in: model)?.isDisabled == true)
    }

    @Test func actionListWithPrioritiesAndHints() {
        let model = GitHeaderMapper.model(for: GitSnapshotFixture.clean, baseName: "dev", ticket: .standard)

        #expect(model.actions.map(\.id) == [.fetch, .pull, .push, .forcePush, .rebase, .updateBase])
        #expect(model.actions.map(\.title) == ["Fetch", "Pull", "Push", "Force Push…", "Rebase on dev…", "Update dev"])
        #expect(model.actions.map(\.systemImage) == [
            "arrow.down.circle", "arrow.down", "arrow.up", "arrow.up.square", "arrow.triangle.merge", "arrow.down.to.line"
        ])
        #expect(model.actions.map(\.priority) == [3, 5, 6, 2, 4, 1])
        #expect(disabled(model).isEmpty)
        #expect(action(.fetch, in: model)?.hint == "Download new commits and branches from the remote. git fetch --prune <remote>")
        #expect(action(.pull, in: model)?.hint == "Fast-forward this branch from its remote. git pull --ff-only")
        #expect(action(.push, in: model)?.hint == "Send your commits. git push")
        #expect(action(.forcePush, in: model)?.hint == "Replace the remote branch with yours. Asks first. git push --force-with-lease")
        #expect(action(.rebase, in: model)?.hint == "Fetch dev and replay your commits on top of it. Asks first. git rebase --autostash origin/dev")
        #expect(action(.updateBase, in: model)?.hint == "Fast-forward the local dev branch without switching to it")
    }

    @Test func changesAddStash() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.changedFiles = 1
        snapshot.stashCount = 3

        let stash = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard).actions.last

        #expect(stash == GitHeaderActionModel(
            id: .stash,
            title: "Stash…",
            systemImage: "tray.and.arrow.down",
            hint: "Put away all local changes, untracked files too, with an optional message. git stash push --include-untracked",
            priority: 0,
            isDisabled: false
        ))
    }

    @Test func cleanTreeWithStashAddsPopStash() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.stashCount = 1

        let pop = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard).actions.last

        #expect(pop == GitHeaderActionModel(
            id: .popStash,
            title: "Pop Stash",
            systemImage: "tray.and.arrow.up",
            hint: "Bring back the newest stash. git stash pop",
            priority: 0,
            isDisabled: false
        ))
    }

    @Test func rebaseInProgress() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.operation = "rebase"

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.operationText == "Rebase in progress. Resolve conflicts in the terminal or Xcode, then continue.")
        #expect(model.canContinueOperation)
        #expect(disabled(model) == [.rebase])
    }

    @Test func mergeInProgressCannotContinueFromDevHub() {
        var snapshot = GitSnapshotFixture.clean
        snapshot.operation = "merge"

        let model = GitHeaderMapper.model(for: snapshot, baseName: "dev", ticket: .standard)

        #expect(model.operationText == "Merge in progress. Resolve conflicts in the terminal or Xcode, then continue.")
        #expect(model.canContinueOperation == false)
    }

    @Test func checkoutLabel() {
        let path = NSHomeDirectory() + "/Projects/ExampleApp"

        #expect(GitHeaderMapper.checkoutLabel(path: path, worktree: nil) == "~/Projects/ExampleApp")
        #expect(GitHeaderMapper.checkoutLabel(path: path, worktree: WorktreeFixture.main) == "Main checkout")
        #expect(GitHeaderMapper.checkoutLabel(path: path, worktree: WorktreeFixture.linked) == "Worktree feature/login")
    }

    @Test func checkoutTitle() {
        var detached = WorktreeFixture.linked
        detached.branch = nil

        #expect(GitHeaderMapper.checkoutTitle(WorktreeFixture.main) == "dev · main checkout")
        #expect(GitHeaderMapper.checkoutTitle(WorktreeFixture.linked) == "feature/login")
        #expect(GitHeaderMapper.checkoutTitle(detached) == "detached @ b2c3d4e")
    }

    @Test func fetchedText() {
        #expect(GitHeaderMapper.fetchedText(Date(timeIntervalSinceNow: -60)).hasPrefix("fetched "))
    }

    private func action(_ id: GitHeaderAction, in model: GitHeaderModel) -> GitHeaderActionModel? {
        model.actions.first { $0.id == id }
    }

    private func disabled(_ model: GitHeaderModel) -> [GitHeaderAction] {
        model.actions.filter(\.isDisabled).map(\.id)
    }
}
