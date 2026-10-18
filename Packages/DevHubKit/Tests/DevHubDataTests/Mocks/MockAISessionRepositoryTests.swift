import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockAISessionRepositoryTests {
    @Test func answersMockSessions() async {
        #expect(await MockAISessionRepository().sessions() == MockData.aiSessions)
    }
}
