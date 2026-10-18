import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct CompositeAISessionRepositoryTests {
    @Test func mergesAllRepositoriesNewestFirst() async {
        let claude = SpyAISessionRepository()
        let copilot = SpyAISessionRepository()
        claude.sessionsResult = [session("old", provider: .claude, at: 1), session("new", provider: .claude, at: 3)]
        copilot.sessionsResult = [session("middle", provider: .copilot, at: 2)]

        let sessions = await CompositeAISessionRepository(repositories: [claude, copilot]).sessions()

        #expect(sessions.map(\.id) == ["new", "middle", "old"])
    }

    private func session(_ id: String, provider: AIProvider, at seconds: TimeInterval) -> AISession {
        AISession(id: id, provider: provider, title: id, lastPrompt: nil, cwd: "/repo", gitBranch: nil, startedAt: nil, updatedAt: Date(timeIntervalSince1970: seconds), folderExists: true)
    }
}
