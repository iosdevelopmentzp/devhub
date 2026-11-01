import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ShellAITextRepositoryTests {
    @Test func aCleanExitGivesTheCleanedAnswer() throws {
        #expect(try ShellAITextRepository.answer(status: 0, lines: ["", "```", "feat: add calls", "```"], tool: "claude") == "feat: add calls")
    }

    @Test func exitCode127MeansTheToolIsMissing() {
        #expect(throws: AITextError.notInstalled("copilot")) {
            try ShellAITextRepository.answer(status: 127, lines: ["sh: copilot: command not found"], tool: "copilot")
        }
    }

    @Test func anotherFailureKeepsTheLastLines() {
        let lines = ["line 1", "", "Error: Access denied by policy settings", "  • Your Copilot subscription does not include this feature"]

        #expect(throws: AITextError.command("line 1\nError: Access denied by policy settings\n  • Your Copilot subscription does not include this feature")) {
            try ShellAITextRepository.answer(status: 1, lines: lines, tool: "copilot")
        }
        #expect(throws: AITextError.command("claude exited with code 2.")) {
            try ShellAITextRepository.answer(status: 2, lines: [], tool: "claude")
        }
    }

    @Test func anEmptyAnswerIsAnError() {
        #expect(throws: AITextError.emptyAnswer) {
            try ShellAITextRepository.answer(status: 0, lines: ["", "  "], tool: "claude")
        }
    }

    @Test func theSearchPathAddsTheUsualInstallFolders() {
        let path = ShellAITextRepository.searchPath(home: URL(fileURLWithPath: "/Users/alex"), inherited: "/usr/bin:/bin")

        #expect(path == "/Users/alex/.local/bin:/Users/alex/.claude/local:/Users/alex/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin")
    }
}
