import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct XcodeDiskCleanupRepositoryTests {
    @Test func duGivesTheTotalOfEveryPath() {
        #expect(XcodeDiskCleanupRepository.sizeArguments(["/a", "/b c"]) == ["-sck", "/a", "/b c"])
        let expected: Int64 = 30 * 1024
        #expect(XcodeDiskCleanupRepository.total(fromDu: "10\t/a\n20\t/b c\n30\ttotal\n") == expected)
        #expect(XcodeDiskCleanupRepository.total(fromDu: "") == nil)
    }

    @Test func removeEndsTheOptions() {
        #expect(XcodeDiskCleanupRepository.removeArguments(["/a", "-b"]) == ["-rf", "--", "/a", "-b"])
    }

    @Test func aPathOutsideTheAllowedFoldersIsRefusedWithoutAProcess() async throws {
        let home = try TemporaryDirectory()
        let recorder = SpyCommandRecorder()
        let repository = XcodeDiskCleanupRepository(shell: ShellRunner(recorder: recorder), home: home.url, derivedDataRoot: home.url.appendingPathComponent("Library/Developer/Xcode/DerivedData"))
        let item = DiskCleanupItem(id: "archives", kind: .archives, paths: [home.path("Documents/example-app")])

        await #expect(throws: DiskCleanupError.self) {
            try await repository.clean(item)
        }
        #expect(recorder.events.isEmpty)
    }

    @Test func aKnownSizeNeedsNoProcess() async throws {
        let recorder = SpyCommandRecorder()
        let repository = XcodeDiskCleanupRepository(shell: ShellRunner(recorder: recorder), home: URL(fileURLWithPath: "/Users/alex"), derivedDataRoot: URL(fileURLWithPath: "/Users/alex/Library/Developer/Xcode/DerivedData"))

        let size = await repository.size(of: DiskCleanupItem(id: "runtime:x", kind: .simulatorRuntime, size: 42))

        #expect(size == 42)
        #expect(recorder.events.isEmpty)
    }
}
