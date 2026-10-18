import DevHubDomain
import Foundation

enum AISessionFixture {
    static let session = AISession(
        id: "5f0c2d8e-1b7a-4c3e-9a51-0e2f6b7d9c41",
        title: "Fix the worktree delete confirmation",
        lastPrompt: "Now run the build again",
        cwd: "/Users/dev/Projects/DevHub",
        gitBranch: "feature/worktree-delete",
        startedAt: nil,
        updatedAt: Date(timeIntervalSince1970: 1_000_000),
        folderExists: true
    )
}
