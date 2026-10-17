import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct GhDiffParserTests {
    @Test func filesMapThePatchAndTheKind() throws {
        let files = try GhDiffParser.files(from: GhFixture.files)

        #expect(files.map(\.path) == ["login.txt", "notes.txt", "icon.png", "new.txt"])
        #expect(files.map(\.kind) == [.added, .modified, .added, .renamed])
        #expect(files[1].diff.lines == ["@@ -1,3 +1,4 @@", " line one", "-line two", "+line two changed", " line three", "+line four"])
        #expect(files[1].additions == 2)
        #expect(files[1].deletions == 1)
        #expect(files[2].diff.isBinary)
        #expect(files[3].oldPath == "old.txt")
        #expect(files[3].isTooLarge == false)
    }
}
