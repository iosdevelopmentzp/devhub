import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct PullRequestFileGroupChipMapperTests {
    private let groups = [
        PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*", "*Tests.swift"], isHiddenByDefault: true),
        PullRequestFileGroup(name: "App", patterns: ["*/App/*"], isHiddenByDefault: false),
    ]
    private let matches = [
        FileGroupMatch(name: "Tests", paths: ["AppTests/LoginTests.swift", "AppTests/MenuTests.swift"], isHiddenByDefault: true),
        FileGroupMatch(name: "App", paths: ["Sources/App/Login.swift"], isHiddenByDefault: false),
    ]

    @Test func aHiddenGroupIsGreyWithAStruckEyeAndOffersToShow() {
        let chips = PullRequestFileGroupChipMapper.models(for: matches, groups: groups, toggled: [])

        #expect(chips.map(\.id) == ["Tests", "App"])
        #expect(chips[0].title == "Tests 2")
        #expect(chips[0].icon == "eye.slash")
        #expect(chips[0].tint == .secondary)
        #expect(chips[0].isHidden)
        #expect(chips[0].hint == "2 files are in the group Tests (*Tests/*, *Tests.swift). Click to show them. The groups come from git.pullRequests.fileGroups in project.json.")
        #expect(chips[1].title == "App 1")
        #expect(chips[1].icon == "eye")
        #expect(chips[1].tint == .blue)
        #expect(chips[1].isHidden == false)
        #expect(chips[1].hint == "1 file is in the group App (*/App/*). Click to hide it. The groups come from git.pullRequests.fileGroups in project.json.")
    }

    @Test func aToggleFlipsTheChip() {
        let chips = PullRequestFileGroupChipMapper.models(for: matches, groups: groups, toggled: ["Tests", "App"])

        #expect(chips.map(\.isHidden) == [false, true])
        #expect(chips.map(\.icon) == ["eye", "eye.slash"])
    }
}
