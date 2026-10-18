import Foundation
import DevHubDomain

struct MockCopilotUsageRepository: CopilotUsageRepository {

    func fetch() async throws -> CopilotUsage? {
        var usage = MockData.copilotUsage
        usage.updatedAt = .now
        return usage
    }
}
