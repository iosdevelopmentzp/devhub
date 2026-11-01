import Foundation
import DevHubDomain

struct AIWriteButtonModel: Equatable {
    struct Choice: Identifiable, Equatable {
        let id: AIProvider
        var title: String
    }

    var title: String
    var hint: String
    var defaultProvider: AIProvider
    var choices: [Choice]
    var isRunning: Bool
    var isEnabled: Bool
    var stopHint: String

    static let preview = AIWriteButtonModel(
        title: "Write with AI",
        hint: "Claude Code writes a commit message from the staged diff",
        defaultProvider: .claude,
        choices: [Choice(id: .claude, title: "Claude Code (default)"), Choice(id: .copilot, title: "Copilot CLI")],
        isRunning: false,
        isEnabled: true,
        stopHint: "Stop Claude Code"
    )
}
