import Foundation
import DevHubDomain

struct MockAITextRepository: AITextRepository {
    func generate(prompt: String, command: String, cwd: String?) async throws -> String {
        try await Task.sleep(for: .seconds(1))
        if prompt.hasPrefix("Write a git commit message") {
            return MockData.aiCommitMessage
        }
        if prompt.hasPrefix("Explain") {
            return MockData.aiExplanation
        }
        return MockData.aiPullRequestText
    }
}
