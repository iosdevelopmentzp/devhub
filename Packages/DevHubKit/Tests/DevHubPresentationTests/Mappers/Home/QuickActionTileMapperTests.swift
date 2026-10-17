import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct QuickActionTileMapperTests {
    @Test func buildRunNamesTheSchemeAndFollowsTheBuild() {
        let idle = QuickActionTileMapper.model(for: .builtin(.buildRun), scheme: "ExampleApp", branch: "main", isBuildRunning: false, isRunning: false)
        let busy = QuickActionTileMapper.model(for: .builtin(.buildRun), scheme: "ExampleApp", branch: "main", isBuildRunning: true, isRunning: false)

        #expect(idle.title == "Build & Run")
        #expect(idle.subtitle == "Scheme ExampleApp")
        #expect(idle.tint == .green)
        #expect(idle.isEnabled)
        #expect(busy.isRunning)
        #expect(busy.isEnabled == false)
    }

    @Test func copyBranchNeedsABranch() {
        #expect(QuickActionTileMapper.model(for: .builtin(.copyBranch), scheme: nil, branch: nil, isBuildRunning: false, isRunning: false).isEnabled == false)
        #expect(QuickActionTileMapper.model(for: .builtin(.copyBranch), scheme: nil, branch: "main", isBuildRunning: false, isRunning: false).subtitle == "main")
    }

    @Test func everyBuiltInHasItsOwnIcon() {
        #expect(Set(BuiltinAction.allCases.map(QuickActionTileMapper.systemImage)).count == BuiltinAction.allCases.count)
    }

    @Test func aConfigActionUsesItsOwnFields() {
        var action = ConfigSample.action("clean")
        action.config.subtitle = "Removes DerivedData"
        action.config.tint = .red

        let model = QuickActionTileMapper.model(for: .config(action), scheme: nil, branch: nil, isBuildRunning: true, isRunning: true)

        #expect(model.id == "clean")
        #expect(model.subtitle == "Removes DerivedData")
        #expect(model.tint == .red)
        #expect(model.isRunning)
        #expect(model.isEnabled == false)
    }
}
