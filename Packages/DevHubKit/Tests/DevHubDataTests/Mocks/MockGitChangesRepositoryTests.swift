import DevHubDomain
import Testing
@testable import DevHubMocks

@Suite struct MockGitChangesRepositoryTests {
    private let repository = MockGitChangesRepository()

    @Test func answersChangesInEveryArea() async throws {
        let changes = try await repository.changes(in: "~/App")

        #expect(Set(changes.map(\.area)) == [.staged, .unstaged, .untracked])
    }

    @Test func diffNamesTheFile() async throws {
        let change = GitFileChange(path: "File.swift", originalPath: nil, area: .unstaged, kind: .modified)

        let diff = try await repository.diff(for: change, in: "~/App")

        #expect(diff.lines.first == "diff --git a/File.swift b/File.swift")
        #expect(diff.isBinary == false)
        #expect(diff.droppedLines == 0)
    }
}
