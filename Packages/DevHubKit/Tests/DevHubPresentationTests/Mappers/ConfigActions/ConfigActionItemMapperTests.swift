import Testing
import DevHubDomain
import DevHubUI
@testable import DevHubPresentation

@Suite struct ConfigActionItemMapperTests {
    @Test func takesTitleIconAndTint() {
        var action = ConfigSample.action("clean")
        action.config.icon = "trash"
        action.config.tint = .red

        let model = ConfigActionItemMapper.model(for: action, isRunning: false)

        #expect(model.title == "Clean")
        #expect(model.systemImage == "trash")
        #expect(model.tint == .red)
        #expect(model.isEnabled)
    }

    @Test func runningOrBlockedActionsAreDisabled() {
        #expect(ConfigActionItemMapper.model(for: ConfigSample.action("a"), isRunning: true).isEnabled == false)
        #expect(ConfigActionItemMapper.model(for: ConfigSample.action("b", isExecutable: false), isRunning: false).isEnabled == false)
        #expect(ConfigActionItemMapper.model(for: ConfigSample.action("c"), isRunning: false).systemImage == "terminal")
    }

    @Test func everyConfigTintHasAUITint() {
        #expect(ConfigTint.allCases.map(ConfigTintMapper.tint) == [.gray, .red, .orange, .yellow, .green, .teal, .blue, .indigo, .purple, .pink])
        #expect(ConfigTintMapper.tint(nil) == .gray)
    }
}
