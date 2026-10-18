import Foundation
import DevHubDomain

struct MockAISessionRepository: AISessionRepository {

    func sessions() async -> [AISession] {
        MockData.aiSessions
    }
}
