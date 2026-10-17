import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct StashRowMapperTests {
    @Test func aStashShowsItsReferenceMessageAndBranch() {
        let stash = GitStash(index: 3, branch: "feature/login", message: "half done", date: Date(timeIntervalSinceNow: -60))

        let model = StashRowMapper.model(for: stash, isBusy: false)

        #expect(model.id == 3)
        #expect(model.reference == "stash@{3}")
        #expect(model.message == "half done")
        #expect(model.branch == "feature/login")
        #expect(model.dateText != nil)
        #expect(model.dropMessage == "Drop stash@{3}? Its changes are lost.")
        #expect(model.areActionsEnabled)
    }

    @Test func anEmptyMessageAndABusyRepository() {
        let model = StashRowMapper.model(for: GitStash(index: 0, branch: nil, message: "", date: nil), isBusy: true)

        #expect(model.message == "No message")
        #expect(model.branch == nil)
        #expect(model.dateText == nil)
        #expect(model.areActionsEnabled == false)
    }
}
