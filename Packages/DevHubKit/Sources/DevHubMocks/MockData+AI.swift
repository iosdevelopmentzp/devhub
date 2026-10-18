import Foundation
import DevHubDomain

extension MockData {
    package static let aiSessions: [AISession] = [
        AISession(id: "4d24d22c-f5ad-40e5-b94c-2ed1a330f4f1", provider: .claude, title: "DevHub: feature stores and hover hints", lastPrompt: "add a Claude tab with all sessions", cwd: "/Users/dev/Documents/Projects/DevHub", gitBranch: "main", startedAt: ago(days: 2), updatedAt: ago(minutes: 4), folderExists: true),
        AISession(id: "6e5462e5-bfaa-4bf3-bb37-74efa955acb4", provider: .claude, title: "ABC-2395 age verification alert", lastPrompt: "open the MR", cwd: "/Users/dev/Documents/Projects/example-app/.worktrees/ABC-2395-age-verification-alert", gitBranch: "ABC-2395-age-verification-alert", startedAt: ago(days: 1), updatedAt: ago(hours: 3), folderExists: true),
        AISession(id: "9b1f0e7a-2c4d-4f6a-8e3b-5d7c9a1b3e5f", provider: .copilot, title: "Split the run bar into smaller views", lastPrompt: "run the tests again", cwd: "/Users/dev/Documents/Projects/DevHub", gitBranch: "feature/run-bar", startedAt: ago(days: 1), updatedAt: ago(hours: 1), folderExists: true),
        AISession(id: "dc31ca40-0b73-42a6-9d36-252f1aa41ab8", provider: .claude, title: "Socket audit notes", lastPrompt: nil, cwd: "/Users/dev/Documents/Projects/example-app/docs/socket-audit", gitBranch: nil, startedAt: ago(days: 6), updatedAt: ago(days: 5), folderExists: false)
    ]
}
