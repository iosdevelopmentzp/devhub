import DevHubDomain
import Testing
@testable import DevHubData

@Suite struct GitHiddenFilesParserTests {
    @Test func keepsOnlyTheHiddenFilesWithTheirFlags() {
        let output = [
            "H 100644 aaa 0\tREADME.md",
            "S 100644 bbb 0\tConfig/Local.xcconfig",
            "h 100644 ccc 0\tsp ace.plist",
            "s 100644 ddd 0\tboth.txt",
        ].joined(separator: "\0") + "\0"

        #expect(GitHiddenFilesParser.entries(output) == [
            .init(path: "Config/Local.xcconfig", flags: [.skipWorktree], objectID: "bbb"),
            .init(path: "sp ace.plist", flags: [.assumeUnchanged], objectID: "ccc"),
            .init(path: "both.txt", flags: [.skipWorktree, .assumeUnchanged], objectID: "ddd"),
        ])
    }

    @Test func aConflictStageIsLeftOut() {
        #expect(GitHiddenFilesParser.entries("h 100644 aaa 2\tconflict.txt\0").isEmpty)
    }
}
