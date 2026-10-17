import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GlabDiffParserTests {
    @Test func filesAreMappedWithKindAndCounts() throws {
        let files = try GlabDiffParser.files(from: GlabGraphQLFixture.diffs)

        #expect(files.map(\.kind) == [.modified, .added, .deleted, .renamed, .modified])
        #expect(files[0].path == "a.swift")
        #expect(files[0].additions == 2)
        #expect(files[0].deletions == 1)
        #expect(files[0].diff == GitDiff(lines: ["@@ -1,2 +1,2 @@", "-old", "+new", "+more", " context"], droppedLines: 0, isBinary: false))
        #expect(files[3].oldPath == "old/d.swift")
        #expect(files[3].path == "new/d.swift")
        #expect(files[3].diff.lines.isEmpty)
        #expect(files[4].isTooLarge)
    }

    @Test func longDiffsAreCut() throws {
        let body = (0..<2_005).map { "+line \($0)" }.joined(separator: "\\n")
        let data = Data(#"[{"old_path":"a","new_path":"a","diff":"\#(body)"}]"#.utf8)

        let file = try #require(try GlabDiffParser.files(from: data).first)

        #expect(file.diff.lines.count == 2_000)
        #expect(file.diff.droppedLines == 5)
        #expect(file.additions == 2_005)
    }
}
