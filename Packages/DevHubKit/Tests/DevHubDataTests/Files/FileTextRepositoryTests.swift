import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileTextRepositoryTests {
    @Test func writeCreatesTheFoldersAndTheFile() async throws {
        let directory = try TemporaryDirectory()
        let repository = FileTextRepository(scratchRoot: directory.url.appendingPathComponent("scratch", isDirectory: true))
        let path = directory.path("logs/nested/build.log")

        try await repository.write("line\n", to: path)

        #expect(try String(contentsOfFile: path, encoding: .utf8) == "line\n")
    }

    @Test func writeScratchPutsTheFileIntoTheScratchFolder() async throws {
        let directory = try TemporaryDirectory()
        let repository = FileTextRepository(scratchRoot: directory.url.appendingPathComponent("scratch", isDirectory: true))

        let path = try await repository.writeScratch("$ git status\n", name: "output.log")

        #expect(path == directory.path("scratch/output.log"))
        #expect(try String(contentsOfFile: path, encoding: .utf8) == "$ git status\n")
    }
}
