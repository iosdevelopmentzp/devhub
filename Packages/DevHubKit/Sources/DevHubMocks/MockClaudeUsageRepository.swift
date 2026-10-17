import Foundation
import DevHubDomain

struct MockClaudeUsageRepository: ClaudeUsageRepository {

    func fetch() async throws -> ClaudeUsage {
        var usage = MockData.usage
        usage.updatedAt = .now
        return usage
    }
}
