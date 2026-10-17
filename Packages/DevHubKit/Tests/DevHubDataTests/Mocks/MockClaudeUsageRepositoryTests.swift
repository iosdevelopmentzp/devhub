import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockClaudeUsageRepositoryTests {
    @Test func answersMockUsage() async throws {
        let usage = try await MockClaudeUsageRepository().fetch()

        #expect(usage.plan == MockData.usage.plan)
        #expect(usage.limits == MockData.usage.limits)
    }
}
