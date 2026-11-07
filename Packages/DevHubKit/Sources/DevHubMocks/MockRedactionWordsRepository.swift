import Foundation
import DevHubDomain

struct MockRedactionWordsRepository: RedactionWordsRepository {

    func words() async throws -> [RedactionWord] {
        [.word("Example App"), .pattern("ABC-[0-9]+")]
    }
}
