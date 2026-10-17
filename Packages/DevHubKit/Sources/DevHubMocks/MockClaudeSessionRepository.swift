import Foundation
import DevHubDomain

struct MockClaudeSessionRepository: ClaudeSessionRepository {

    func sessions() async -> [ClaudeSession] {
        MockData.claudeSessions
    }
}
