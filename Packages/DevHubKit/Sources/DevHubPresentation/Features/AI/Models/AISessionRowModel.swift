import Foundation
import DevHubDomain
import DevHubUI

struct AISessionRowModel: Identifiable, Equatable {
    let id: AISession.ID
    var title: String
    var icon: String
    var iconTint: Tint
    var providerTag: TagModel
    var dateText: String
    var folderPath: String
    var folderDisplayPath: String
    var branchTag: TagModel?
    var statusTags: [TagModel]
    var lastPrompt: String?
    var resumeCommand: String
    var terminalCommand: String
    var terminalTitle: String
    var canResume: Bool
    var resumeHint: String
    var canShowFolder: Bool

    static let preview = AISessionRowModel(
        id: "5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41",
        title: "Fix the worktree delete confirmation",
        icon: "sparkles",
        iconTint: .orange,
        providerTag: TagModel("Claude", tint: .secondary),
        dateText: "Oct 10, 2026 at 09:41",
        folderPath: "/Users/dev/Projects/DevHub",
        folderDisplayPath: "~/Projects/DevHub",
        branchTag: TagModel("feature/worktree-delete", tint: .blue, systemImage: "arrow.triangle.branch"),
        statusTags: [],
        lastPrompt: "Now run the build again",
        resumeCommand: "cd /Users/dev/Projects/DevHub && claude --resume 5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41",
        terminalCommand: "claude --resume 5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41",
        terminalTitle: "Resumed Claude session",
        canResume: true,
        resumeHint: "Open the terminal in DevHub and run claude --resume",
        canShowFolder: true
    )
}
