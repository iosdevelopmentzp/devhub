import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileReviewPromptRepositoryTests {
    @Test func writesThePromptIntoTheFolderAndReplacesAnOldOne() async throws {
        let directory = try TemporaryDirectory()
        let repository = FileReviewPromptRepository(root: directory.url.appendingPathComponent("prompts", isDirectory: true))

        _ = try await repository.save("old", iid: 21)
        let path = try await repository.save("# Review\n", iid: 21)

        #expect(path == directory.path("prompts/mr-21.md"))
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "# Review\n")
    }

    @Test func aNamedPromptGetsItsOwnFile() async throws {
        let directory = try TemporaryDirectory()
        let repository = FileReviewPromptRepository(root: directory.url.appendingPathComponent("prompts", isDirectory: true))

        let path = try await repository.save("# Fix\n", name: "fix-tests-feature-login")

        #expect(path == directory.path("prompts/fix-tests-feature-login.md"))
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "# Fix\n")
    }
}
