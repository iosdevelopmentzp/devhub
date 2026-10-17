import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct ProjectCardMapperTests {
    @Test func withoutMainWorktree() {
        let model = ProjectCardMapper.model(for: ProjectFixture.exampleApp, main: nil, mainCheckoutPath: "/Users/dev/Projects/ExampleApp")

        #expect(model.name == "ExampleApp")
        #expect(model.path == "/Users/dev/Projects/ExampleApp")
        #expect(model.mainCheckoutPath == "/Users/dev/Projects/ExampleApp")
        #expect(model.branchTag == TagModel("—", tint: .blue, systemImage: "arrow.triangle.branch"))
        #expect(model.statusTags == [TagModel("clean", tint: .green, systemImage: "checkmark")])
    }

    @Test func cleanMainWorktree() {
        let model = ProjectCardMapper.model(for: ProjectFixture.exampleApp, main: WorktreeFixture.main, mainCheckoutPath: WorktreeFixture.mainPath)

        #expect(model.branchTag == TagModel("dev", tint: .blue, systemImage: "arrow.triangle.branch"))
        #expect(model.statusTags == [TagModel("clean", tint: .green, systemImage: "checkmark")])
    }

    @Test func dirtyMainWorktreeAheadAndBehind() {
        var main = WorktreeFixture.main
        main.changedFiles = 3
        main.ahead = 2
        main.behind = 1

        let model = ProjectCardMapper.model(for: ProjectFixture.exampleApp, main: main, mainCheckoutPath: WorktreeFixture.mainPath)

        #expect(model.statusTags == [
            TagModel("3 changed", tint: .orange, systemImage: "pencil"),
            TagModel("↑2"),
            TagModel("↓1", tint: .red)
        ])
    }
}
