import Foundation
import DevHubDomain

struct MockReviewPromptRepository: ReviewPromptRepository {

    func save(_ prompt: String, iid: Int) async throws -> String {
        "~/.devhub/prompts/mr-\(iid).md"
    }

    func save(_ prompt: String, name: String) async throws -> String {
        "~/.devhub/prompts/\(name).md"
    }
}
