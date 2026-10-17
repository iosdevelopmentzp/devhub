import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileManagerModificationDateTests {
    private let directory: TemporaryDirectory

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test func readsModificationDate() throws {
        let file = try directory.write("x", to: "file.txt")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: file.path)

        #expect(FileManager.default.modificationDate(of: file) == date)
    }

    @Test func missingFileIsDistantPast() {
        #expect(FileManager.default.modificationDate(of: directory.url.appendingPathComponent("missing")) == .distantPast)
    }
}
