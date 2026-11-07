import Testing
@testable import DevHubDomain

@Suite struct FileGroupPolicyTests {
    private let groups = [
        PullRequestFileGroup(name: "Tests", patterns: ["*Tests/*", "*Tests.swift"], isHiddenByDefault: true),
        PullRequestFileGroup(name: "App", patterns: ["*/App/*"], isHiddenByDefault: false),
    ]
    private let paths = ["Sources/App/Login.swift", "Sources/App/LoginTests.swift", "Tests/AppTests/MenuTests.swift", "docs/readme.md"]

    @Test func aPathLandsInTheFirstGroupThatMatchesIt() {
        let matches = FileGroupPolicy.matches(in: paths, groups: groups)

        #expect(matches.map(\.name) == ["Tests", "App"])
        #expect(matches[0].paths == ["Sources/App/LoginTests.swift", "Tests/AppTests/MenuTests.swift"])
        #expect(matches[0].isHiddenByDefault)
        #expect(matches[1].paths == ["Sources/App/Login.swift"])
        #expect(matches[1].isHiddenByDefault == false)
        #expect(FileGroupPolicy.groupedPaths(in: matches) == ["Sources/App/LoginTests.swift", "Tests/AppTests/MenuTests.swift", "Sources/App/Login.swift"])
        #expect(FileGroupPolicy.groupName(of: "Sources/App/Login.swift", in: matches) == "App")
        #expect(FileGroupPolicy.groupName(of: "docs/readme.md", in: matches) == nil)
    }

    @Test func aGroupWithoutAMatchIsLeftOut() {
        #expect(FileGroupPolicy.matches(in: ["docs/readme.md"], groups: groups).isEmpty)
        #expect(FileGroupPolicy.matches(in: paths, groups: []).isEmpty)
    }

    @Test func aToggleFlipsTheDefaultOfAGroup() {
        let matches = FileGroupPolicy.matches(in: paths, groups: groups)

        #expect(FileGroupPolicy.hiddenPaths(in: matches, toggled: []) == ["Sources/App/LoginTests.swift", "Tests/AppTests/MenuTests.swift"])
        #expect(FileGroupPolicy.hiddenPaths(in: matches, toggled: ["Tests"]).isEmpty)
        #expect(FileGroupPolicy.hiddenPaths(in: matches, toggled: ["App"]) == Set(paths.dropLast()))
        #expect(FileGroupPolicy.isHidden(matches[1], toggled: ["App"]))
        #expect(FileGroupPolicy.isHidden(matches[1], toggled: []) == false)
    }
}
