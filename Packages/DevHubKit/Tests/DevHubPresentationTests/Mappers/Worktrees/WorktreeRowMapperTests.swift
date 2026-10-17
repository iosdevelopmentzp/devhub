import DevHubDomain
import DevHubTestSupport
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct WorktreeRowMapperTests {
    let clean = TagModel("clean", tint: .green, systemImage: "checkmark")
    let bootstrapTag = TagModel(
        "needs bootstrap",
        tint: .orange,
        systemImage: "wrench.and.screwdriver",
        hint: "Pods is missing in this worktree. Click to run scripts/bootstrap.sh."
    )

    @Test func mainCheckout() {
        let model = row(WorktreeFixture.main)

        #expect(model.id == WorktreeFixture.main.id)
        #expect(model.title == "dev")
        #expect(model.titleCopyValue == "dev")
        #expect(model.path == WorktreeFixture.mainPath)
        #expect(model.pathCopyLabel == WorktreeFixture.mainPath.abbreviatingHome)
        #expect(model.displayPath == WorktreeFixture.mainPath.abbreviatingHome)
        #expect(model.head == "a1b2c3d")
        #expect(model.branch == "dev")
        #expect(model.lastCommit == "Merge branch 'feature/login'")
        #expect(model.lastActivityText == nil)
        #expect(model.icon == "house.fill")
        #expect(model.iconHint == "Main checkout")
        #expect(model.iconTint == .indigo)
        #expect(model.titleTags == [TagModel("main", tint: .indigo)])
        #expect(model.statusTags == [clean])
        #expect(model.canDelete == false)
        #expect(model.buildSourceIDToUse == nil)
        #expect(model.buildAndRunTint == .green)
        #expect(model.deleteTint == .red)
        #expect(model.deleteTitle == "Delete worktree dev?")
        #expect(model.deleteBranchLabel == "Delete branch dev")
        #expect(model.derivedDataLabel == "No DerivedData found")
        #expect(model.canDeleteDerivedData == false)
    }

    @Test func linkedWorktreeInProgress() {
        let model = row(WorktreeFixture.linked)

        #expect(model.icon == "arrow.triangle.branch")
        #expect(model.iconHint == "Linked worktree")
        #expect(model.iconTint == .blue)
        #expect(model.titleTags.isEmpty)
        #expect(model.statusTags == [clean])
        #expect(model.lastActivityText?.isEmpty == false)
        #expect(model.displayPath == "/Users/dev/Projects/ExampleApp-login".abbreviatingHome)
        #expect(model.canDelete)
        #expect(model.canOpen)
        #expect(model.canBuildAndRun)
        #expect(model.canUseAsBuildSource)
        #expect(model.buildSourceIDToUse == WorktreeFixture.linked.id)
        #expect(model.deleteWarnings.isEmpty)
        #expect(model.defaultDeleteBranch == false)
    }

    @Test func aWorktreeInsideTheMainCheckoutShowsARelativePath() {
        let model = row(WorktreeFixture.nested)

        #expect(model.icon == "arrow.triangle.branch")
        #expect(model.iconHint == "Linked worktree")
        #expect(model.displayPath == ".worktrees/gifts")
        #expect(model.lastCommit == nil)
        #expect(model.titleTags.isEmpty)
    }

    @Test func withoutABootstrapScriptTheRowCannotRunOne() {
        let model = WorktreeRowMapper.model(
            for: WorktreeFixture.linked,
            baseBranch: "origin/dev",
            mainCheckoutPath: WorktreeFixture.mainPath,
            derivedDataSize: nil,
            isBusy: false,
            isBootstrapping: false,
            isBuildSource: false,
            buildIsRunning: false,
            git: .standard,
            configActions: []
        )

        #expect(model.canRunBootstrap == false)
    }

    @Test func dirtyWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.changedFiles = 3

        let model = row(worktree)

        #expect(model.iconTint == .orange)
        #expect(model.statusTags == [TagModel("3 changed", tint: .orange, systemImage: "pencil")])
        #expect(model.deleteWarnings == ["3 uncommitted changes will be lost (git worktree remove --force)."])
    }

    @Test func mergedWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.isMerged = true
        worktree.changedFiles = 2

        let model = row(worktree)

        #expect(model.icon == "checkmark.seal.fill")
        #expect(model.iconHint == "Finished: merged or the remote branch is deleted")
        #expect(model.iconTint == .purple)
        #expect(model.statusTags == [
            TagModel("2 changed", tint: .orange, systemImage: "pencil"),
            TagModel("merged into dev", tint: .purple, systemImage: "arrow.triangle.merge")
        ])
        #expect(model.defaultDeleteBranch)
    }

    @Test func upstreamGoneWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.isUpstreamGone = true

        let model = row(worktree)

        #expect(model.icon == "checkmark.seal.fill")
        #expect(model.statusTags == [clean, TagModel("remote branch deleted", tint: .purple, systemImage: "icloud.slash")])
        #expect(model.defaultDeleteBranch)
    }

    @Test func notPushedWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.upstream = nil
        worktree.ahead = 2

        let model = row(worktree)

        #expect(model.statusTags == [
            clean,
            TagModel("not pushed", tint: .orange, systemImage: "icloud.slash"),
            TagModel("↑2", hint: "Commits ahead / behind upstream")
        ])
        #expect(model.deleteWarnings == ["The branch was never pushed. Keep the branch to keep its commits."])
    }

    @Test func aheadAndBehindTag() {
        var worktree = WorktreeFixture.linked
        worktree.ahead = 1
        worktree.behind = 4

        let model = row(worktree)

        #expect(model.statusTags.last == TagModel("↑1 ↓4", hint: "Commits ahead / behind origin/feature/login"))
    }

    @Test func missingWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.isMissing = true
        worktree.upstream = nil

        let model = row(worktree)

        #expect(model.icon == "questionmark.folder")
        #expect(model.iconHint == "The folder is gone. Prune removes the entry.")
        #expect(model.iconTint == .red)
        #expect(model.statusTags == [TagModel("folder missing", tint: .red, systemImage: "questionmark.folder")])
        #expect(model.canBuildAndRun == false)
        #expect(model.canOpen == false)
        #expect(model.canUseAsBuildSource == false)
        #expect(model.canDelete == false)
    }

    @Test func detachedWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.branch = nil
        worktree.upstream = nil

        let model = row(worktree)

        #expect(model.title == "detached @ b2c3d4e")
        #expect(model.titleCopyValue == "b2c3d4e")
        #expect(model.statusTags == [clean])
        #expect(model.deleteBranchLabel == nil)
    }

    @Test func lockedWorktree() {
        var worktree = WorktreeFixture.linked
        worktree.isLocked = true

        let model = row(worktree)

        #expect(model.titleTags == [TagModel("locked", systemImage: "lock.fill", hint: "git worktree lock: protected from prune and remove")])
        #expect(model.deleteWarnings == ["The worktree is locked."])
    }

    @Test func configActionsPassThrough() {
        let model = WorktreeRowMapper.model(
            for: WorktreeFixture.linked,
            baseBranch: "origin/dev",
            mainCheckoutPath: WorktreeFixture.mainPath,
            derivedDataSize: nil,
            isBusy: false,
            isBootstrapping: false,
            isBuildSource: false,
            buildIsRunning: false,
            git: .withBootstrap,
            configActions: [.preview]
        )

        #expect(model.configActions == [.preview])
        #expect(row(WorktreeFixture.linked).configActions.isEmpty)
    }

    @Test func bootstrapStates() {
        var worktree = WorktreeFixture.linked
        worktree.needsBootstrap = true

        let needed = row(worktree)
        let running = WorktreeRowMapper.model(
            for: worktree,
            baseBranch: "origin/dev",
            mainCheckoutPath: WorktreeFixture.mainPath,
            derivedDataSize: nil,
            isBusy: false,
            isBootstrapping: true,
            isBuildSource: false,
            buildIsRunning: false,
            git: .withBootstrap,
            configActions: []
        )

        #expect(row(WorktreeFixture.linked).bootstrapTag == nil)
        #expect(row(WorktreeFixture.linked).canRunBootstrap)
        #expect(row(WorktreeFixture.main).canRunBootstrap == false)
        #expect(needed.bootstrapTag == bootstrapTag)
        #expect(needed.bootstrapTitle == "Run scripts/bootstrap.sh")
        #expect(needed.bootstrapRunningText == "Running scripts/bootstrap.sh…")
        #expect(needed.isBootstrapping == false)
        #expect(running.bootstrapTag == nil)
        #expect(running.isBootstrapping)
    }

    @Test func buildSourceBusyAndDerivedData() {
        let model = WorktreeRowMapper.model(
            for: WorktreeFixture.linked,
            baseBranch: "origin/dev",
            mainCheckoutPath: WorktreeFixture.mainPath,
            derivedDataSize: 1_200_000_000,
            isBusy: true,
            isBootstrapping: false,
            isBuildSource: true,
            buildIsRunning: true,
            git: .withBootstrap,
            configActions: []
        )

        #expect(model.isHighlighted)
        #expect(model.isBuildSource)
        #expect(model.isBusy)
        #expect(model.canBuildAndRun == false)
        #expect(model.titleTags == [TagModel(
            "build source",
            tint: .blue,
            systemImage: "play.fill",
            hint: "Build & Run on the Simulators tab builds this checkout"
        )])
        #expect(model.statusTags.count == 2)
        #expect(model.statusTags.last?.tint == .blue)
        #expect(model.statusTags.last?.systemImage == "internaldrive")
        #expect(model.statusTags.last?.hint == "DerivedData of this checkout")
        #expect(model.statusTags.last?.text.isEmpty == false)
        #expect(model.derivedDataLabel.hasPrefix("Delete DerivedData ("))
        #expect(model.canDeleteDerivedData)
    }

    @Test func pathOutsideTheMainCheckoutIsAbbreviated() {
        let model = WorktreeRowMapper.model(
            for: WorktreeFixture.nested,
            baseBranch: "origin/dev",
            mainCheckoutPath: nil,
            derivedDataSize: nil,
            isBusy: false,
            isBootstrapping: false,
            isBuildSource: false,
            buildIsRunning: false,
            git: .withBootstrap,
            configActions: []
        )

        #expect(model.displayPath == WorktreeFixture.nested.path.abbreviatingHome)
    }

    private func row(_ worktree: Worktree) -> WorktreeRowModel {
        WorktreeRowMapper.model(
            for: worktree,
            baseBranch: "origin/dev",
            mainCheckoutPath: WorktreeFixture.mainPath,
            derivedDataSize: nil,
            isBusy: false,
            isBootstrapping: false,
            isBuildSource: false,
            buildIsRunning: false,
            git: .withBootstrap,
            configActions: []
        )
    }
}
