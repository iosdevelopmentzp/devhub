import DevHubDomain
import DevHubUI
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct RemoteBranchRowMapperTests {
    @Test func remoteWithoutLocalBranch() {
        let model = RemoteBranchRowMapper.model(
            for: GitBranchFixture.remote,
            remote: "origin",
            localBranchNames: ["dev"],
            openPullRequest: nil,
            ticket: .standard,
            checkoutPath: { _ in nil },
            isBuildRunning: false,
            isBusy: false
        )

        #expect(model.id == "origin/feature/gifts")
        #expect(model.remoteName == "origin/feature/gifts")
        #expect(model.localName == "feature/gifts")
        #expect(model.tags.isEmpty)
        #expect(model.dateText == nil)
        #expect(model.author == "sam")
        #expect(model.subject == "ABC-2: Gift animation")
        #expect(model.checkOutHint == "Check out as a new local branch")
        #expect(model.canBuild)
        #expect(model.canCreateWorktree)
        #expect(model.areActionsEnabled)
    }

    @Test func remoteWithLocalBranchInACheckout() {
        var branch = GitBranchFixture.remote
        branch.commitDate = Date(timeIntervalSinceNow: -86_400)

        let model = RemoteBranchRowMapper.model(
            for: branch,
            remote: "origin",
            localBranchNames: ["feature/gifts"],
            openPullRequest: nil,
            ticket: .standard,
            checkoutPath: { $0 == "feature/gifts" ? "/tmp/gifts" : nil },
            isBuildRunning: true,
            isBusy: true
        )

        #expect(model.tags == [TagModel("local", tint: .blue)])
        #expect(model.dateText?.isEmpty == false)
        #expect(model.checkOutHint == "Switch to the local branch")
        #expect(model.canBuild == false)
        #expect(model.canCreateWorktree == false)
        #expect(model.areActionsEnabled == false)
    }
}
