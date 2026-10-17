import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockClaudeSessionRepositoryTests {
    @Test func answersMockSessions() async {
        #expect(await MockClaudeSessionRepository().sessions() == MockData.claudeSessions)
    }
}
