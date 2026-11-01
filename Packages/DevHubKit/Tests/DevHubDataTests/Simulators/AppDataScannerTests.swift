import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct AppDataScannerTests {
    private let folder: TemporaryDirectory

    init() throws {
        folder = try TemporaryDirectory()
        _ = try folder.write("12345", to: "data/Documents/notes.txt")
        _ = try folder.write("123", to: "data/Documents/inbox/mail.txt")
        _ = try folder.write("1234567890", to: "data/Library/Application Support/Model.sqlite")
        _ = try folder.write("12", to: "data/Library/Application Support/Model.sqlite-wal")
        _ = try folder.write("1", to: "data/Library/Preferences/com.example.app.plist")
        _ = try folder.write("1234", to: "data/tmp/upload.part")
        _ = try folder.write("meta", to: "group/\(AppDataScanner.metadataFile)")
        _ = try folder.write("123456", to: "group/Library/Shared.db")
    }

    @Test func foldersListOnlyTheFoldersThatExistWithTheirSize() {
        let folders = AppDataScanner.folders(in: folder.path("data"))

        #expect(folders.map(\.name) == ["Documents", "Library/Application Support", "Library/Preferences", "tmp"])
        #expect(folders.map(\.size) == [8, 12, 1, 4])
        #expect(folders.first?.path == folder.path("data/Documents"))
    }

    @Test func groupsGetTheirSize() {
        let sized = AppDataScanner.sized([AppDataFile(name: "group.com.example.app", path: folder.path("group"), size: 0)])

        #expect(sized.map(\.size) == [10])
    }

    @Test func databasesAreFoundInEveryRootWithAPrefix() {
        let databases = AppDataScanner.databases(in: [(prefix: "", path: folder.path("data")), (prefix: "group.com.example.app/", path: folder.path("group"))])

        #expect(databases.map(\.name) == ["group.com.example.app/Library/Shared.db", "Library/Application Support/Model.sqlite"])
        #expect(databases.map(\.size) == [6, 10])
    }

    @Test func clearContainerEmptiesTheFoldersButKeepsThem() throws {
        try AppDataScanner.clearContainer(folder.path("data"))

        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path("data/Documents")).isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path("data/Library")).isEmpty)
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path("data/tmp")).isEmpty)
    }

    @Test func clearGroupKeepsTheContainerMetadata() throws {
        try AppDataScanner.clearGroup(folder.path("group"))

        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path("group")) == [AppDataScanner.metadataFile])
    }

    @Test func clearingAMissingFolderDoesNothing() throws {
        try AppDataScanner.clearContainer(folder.path("missing"))

        #expect(FileManager.default.fileExists(atPath: folder.path("missing")) == false)
    }
}
