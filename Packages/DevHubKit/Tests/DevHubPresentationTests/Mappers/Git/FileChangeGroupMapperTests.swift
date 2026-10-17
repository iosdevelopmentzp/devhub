import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct FileChangeGroupMapperTests {
    let conflicted = GitFileChange(path: "A.swift", originalPath: nil, area: .conflicted, kind: .conflicted)
    let staged = GitFileChange(path: "B.swift", originalPath: nil, area: .staged, kind: .modified)
    let unstaged = GitFileChange(path: "C.swift", originalPath: nil, area: .unstaged, kind: .modified)
    let untracked = GitFileChange(path: "D.swift", originalPath: nil, area: .untracked, kind: .untracked)

    @Test func groupsFollowAreaOrderWithTitlesAndActions() {
        let groups = FileChangeGroupMapper.groups(for: [untracked, unstaged, staged, conflicted], isVisible: { _ in true }, isBusy: false)

        #expect(groups.map(\.id) == [.conflicted, .staged, .unstaged, .untracked])
        #expect(groups.map(\.title) == ["Conflicts 1", "Staged 1", "Changes 1", "New files 1"])
        #expect(groups[0].action == nil)
        #expect(groups[1].action == GroupAction(title: "Unstage All", kind: .unstageAll))
        #expect(groups[2].action == GroupAction(title: "Stage All", kind: .stageAll))
        #expect(groups[3].action == nil)
        #expect(groups.map(\.isActionEnabled) == [true, true, true, true])
        #expect(groups[2].changes == [unstaged])
    }

    @Test func untrackedGetStageAllWhenNothingIsUnstaged() {
        let groups = FileChangeGroupMapper.groups(for: [untracked], isVisible: { _ in true }, isBusy: false)

        #expect(groups.first?.action == GroupAction(title: "Stage All", kind: .stageAll))
    }

    @Test func hiddenUnstagedStillRemoveTheUntrackedAction() {
        let groups = FileChangeGroupMapper.groups(for: [unstaged, untracked], isVisible: { $0.area != .unstaged }, isBusy: false)

        #expect(groups.map(\.id) == [.untracked])
        #expect(groups.first?.action == nil)
    }

    @Test func invisibleChangesAreLeftOutAndEmptyGroupsDropped() {
        let other = GitFileChange(path: "E.swift", originalPath: nil, area: .staged, kind: .added)

        let groups = FileChangeGroupMapper.groups(for: [staged, other], isVisible: { $0.path == "E.swift" }, isBusy: false)

        #expect(groups.count == 1)
        #expect(groups.first?.title == "Staged 1")
        #expect(groups.first?.changes == [other])
    }

    @Test func busyDisablesTheActions() {
        let groups = FileChangeGroupMapper.groups(for: [staged, unstaged], isVisible: { _ in true }, isBusy: true)

        #expect(groups.allSatisfy { $0.isActionEnabled == false })
    }
}
