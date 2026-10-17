import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitCommitFilesParserTests {
    @Test func readsEveryKindWithRenamesAndSpaces() {
        let output = "M\0App/Call View.swift\0A\0App/Gift.swift\0D\0Old.swift\0R087\0Docs/old.md\0Docs/new.md\0C100\0a.txt\0b.txt\0"

        #expect(GitCommitFilesParser.parse(output) == [
            GitCommitFile(path: "App/Call View.swift", originalPath: nil, kind: .modified),
            GitCommitFile(path: "App/Gift.swift", originalPath: nil, kind: .added),
            GitCommitFile(path: "Old.swift", originalPath: nil, kind: .deleted),
            GitCommitFile(path: "Docs/new.md", originalPath: "Docs/old.md", kind: .renamed),
            GitCommitFile(path: "b.txt", originalPath: "a.txt", kind: .copied),
        ])
    }

    @Test func ignoresTheLeadingNewlineAndACutRecord() {
        #expect(GitCommitFilesParser.parse("\nM\0README.md\0R100\0only-old.md\0") == [
            GitCommitFile(path: "README.md", originalPath: nil, kind: .modified),
        ])
    }

    @Test func emptyOutputHasNoFiles() {
        #expect(GitCommitFilesParser.parse("").isEmpty)
    }
}
