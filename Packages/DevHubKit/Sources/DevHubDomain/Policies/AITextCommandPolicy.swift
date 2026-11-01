import Foundation

package enum AITextCommandPolicy {
    package static let defaultClaudeCommand = "claude -p \"$(cat {prompt})\" --output-format text"
    package static let defaultCopilotCommand = "copilot -p \"$(cat {prompt})\" -s --no-ask-user --no-color --stream off"

    package static func commands(_ ai: AIConfig?) -> [AIProvider: String] {
        [
            .claude: meaningful(ai?.textCommands?[AIProvider.claude.rawValue]) ?? defaultClaudeCommand,
            .copilot: meaningful(ai?.textCommands?[AIProvider.copilot.rawValue]) ?? defaultCopilotCommand,
        ]
    }

    package static func script(template: String, promptPath: String) -> String {
        "exec " + ReviewPromptBuilder.command(promptPath: promptPath, template: template)
    }

    package static func tool(of template: String) -> String {
        template.split(separator: " ").first.map(String.init) ?? template
    }

    private static func meaningful(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), trimmed.isEmpty == false else { return nil }
        return trimmed
    }
}
