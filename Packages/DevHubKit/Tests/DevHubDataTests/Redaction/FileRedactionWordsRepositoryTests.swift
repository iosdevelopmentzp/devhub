import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileRedactionWordsRepositoryTests {
    @Test func theWordsComeFromTheDenylistFile() async throws {
        let directory = try TemporaryDirectory()
        let file = try directory.write("# words\nExample Corp\nre:ABC-[0-9]+\n", to: "anonymity-denylist.txt")

        let words = try await FileRedactionWordsRepository(file: file).words()

        #expect(words == [.word("Example Corp"), .pattern("ABC-[0-9]+")])
    }

    @Test func aMissingFileGivesNoWords() async throws {
        let directory = try TemporaryDirectory()

        let words = try await FileRedactionWordsRepository(file: URL(fileURLWithPath: directory.path("missing.txt"))).words()

        #expect(words.isEmpty)
    }
}
