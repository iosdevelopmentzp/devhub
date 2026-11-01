import Foundation
import Testing
@testable import DevHubDomain

@Suite struct AITextCommandPolicyTests {
    @Test func defaultsRunEachToolOnceWithTheirQuietFlags() {
        let commands = AITextCommandPolicy.commands(nil)

        #expect(commands[.claude] == "claude -p \"$(cat {prompt})\" --output-format text")
        #expect(commands[.copilot] == "copilot -p \"$(cat {prompt})\" -s --no-ask-user --no-color --stream off")
    }

    @Test func configWinsAndBlankValuesKeepTheDefault() {
        let commands = AITextCommandPolicy.commands(AIConfig(textCommands: ["claude": "claude -p \"$(cat {prompt})\" --model sonnet", "copilot": "  "]))

        #expect(commands[.claude] == "claude -p \"$(cat {prompt})\" --model sonnet")
        #expect(commands[.copilot] == AITextCommandPolicy.defaultCopilotCommand)
    }

    @Test func theScriptExecsTheCommandWithTheQuotedPromptPath() {
        let script = AITextCommandPolicy.script(template: "claude -p \"$(cat {prompt})\"", promptPath: "/tmp/a b.md")

        #expect(script == "exec claude -p \"$(cat '/tmp/a b.md')\"")
    }

    @Test func theToolIsTheFirstWord() {
        #expect(AITextCommandPolicy.tool(of: "copilot -p x") == "copilot")
        #expect(AITextCommandPolicy.tool(of: "claude") == "claude")
    }

    @Test func gitSettingsCarryTheTextCommands() {
        let settings = GitSettingsPolicy.settings(for: ProjectConfig(ai: AIConfig(textCommands: ["copilot": "copilot -p \"$(cat {prompt})\""])))

        #expect(settings.pullRequests.aiTextCommands[.copilot] == "copilot -p \"$(cat {prompt})\"")
        #expect(settings.pullRequests.aiTextCommands[.claude] == AITextCommandPolicy.defaultClaudeCommand)
    }
}
