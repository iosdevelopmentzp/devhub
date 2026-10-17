import Foundation

package struct ClaudeSession: Identifiable, Hashable, Sendable {
    package let id: String
    package var title: String
    package var lastPrompt: String?
    package var cwd: String
    package var gitBranch: String?
    package var startedAt: Date?
    package var updatedAt: Date
    package var folderExists: Bool

    package init(
        id: String,
        title: String,
        lastPrompt: String?,
        cwd: String,
        gitBranch: String?,
        startedAt: Date?,
        updatedAt: Date,
        folderExists: Bool
    ) {
        self.id = id
        self.title = title
        self.lastPrompt = lastPrompt
        self.cwd = cwd
        self.gitBranch = gitBranch
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.folderExists = folderExists
    }

    package var folderName: String {
        (cwd as NSString).lastPathComponent
    }

    package var resumeCommand: String {
        "cd \(cwd.shellQuoted) && claude --resume \(id)"
    }
}
