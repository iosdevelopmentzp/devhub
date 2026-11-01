import DevHubDomain
import Testing
@testable import DevHubPresentation

@Suite struct AIWriteButtonMapperTests {
    @Test func theDefaultToolComesFirstAndIsMarked() {
        let model = AIWriteButtonMapper.model(title: "Write with AI", purpose: "writes a commit message", defaultProvider: .copilot, isRunning: false, isEnabled: true)

        #expect(model.choices.map(\.id) == [.copilot, .claude])
        #expect(model.choices.map(\.title) == ["Copilot CLI (default)", "Claude Code"])
        #expect(model.hint.hasPrefix("Copilot CLI writes a commit message."))
        #expect(model.defaultProvider == .copilot)
    }

    @Test func runningAndEnabledPassThrough() {
        let model = AIWriteButtonMapper.model(title: "Explain", purpose: "explains", defaultProvider: .claude, isRunning: true, isEnabled: false)

        #expect(model.isRunning)
        #expect(model.isEnabled == false)
        #expect(model.title == "Explain")
    }
}
