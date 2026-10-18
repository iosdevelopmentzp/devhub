import Foundation
import DevHubDomain

struct CompositeAISessionRepository: AISessionRepository {
    let repositories: [any AISessionRepository]

    func sessions() async -> [AISession] {
        await withTaskGroup(of: [AISession].self) { group in
            for repository in repositories {
                group.addTask { await repository.sessions() }
            }
            var all: [AISession] = []
            for await sessions in group {
                all += sessions
            }
            return all.sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}
