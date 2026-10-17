import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubDomain

@Suite struct TemporaryDirectoryTests {
    @Test func writesFileInNestedFolder() throws {
        let directory = try TemporaryDirectory()

        let file = try directory.write("hello", to: "a/b/file.txt")

        #expect(try String(contentsOf: file, encoding: .utf8) == "hello")
        #expect(file.path == directory.path("a/b/file.txt"))
    }

    @Test func removesFolderWhenReleased() throws {
        let url: URL
        do {
            let directory = try TemporaryDirectory()
            url = directory.url
            #expect(FileManager.default.fileExists(atPath: url.path))
        }
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
    }
}
