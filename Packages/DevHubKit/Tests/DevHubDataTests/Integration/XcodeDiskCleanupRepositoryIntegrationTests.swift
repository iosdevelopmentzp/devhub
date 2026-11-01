import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct XcodeDiskCleanupRepositoryIntegrationTests {
    private let home: TemporaryDirectory
    private let recorder = SpyCommandRecorder()

    init() throws {
        home = try TemporaryDirectory()
    }

    private var repository: XcodeDiskCleanupRepository {
        XcodeDiskCleanupRepository(shell: ShellRunner(recorder: recorder), home: home.url, derivedDataRoot: home.url.appendingPathComponent("Library/Developer/Xcode/DerivedData"))
    }

    @Test func theFolderItemsAndTheSimulatorListsAreRead() async throws {
        _ = try home.write("x", to: "Library/Caches/CocoaPods/Pods/a.txt")

        let items = try await repository.items()

        #expect(items.first?.kind == .cocoaPodsCache)
        #expect(items.dropFirst().allSatisfy { $0.kind == .unavailableSimulators || $0.kind == .simulatorRuntime })
    }

    @Test func duMeasuresAndRmDeletesOnlyTheGivenFolder() async throws {
        _ = try home.write(String(repeating: "x", count: 50_000), to: "Library/Developer/Xcode/Archives/2026-10-01/a.bin")
        _ = try home.write("keep", to: "Library/Developer/Xcode/Archives/2026-10-02/b.txt")
        let item = DiskCleanupItem(id: "archives", kind: .archives, paths: [home.path("Library/Developer/Xcode/Archives/2026-10-01")])

        let size = try #require(await repository.size(of: item))
        try await repository.clean(item)

        #expect(size >= 50_000)
        #expect(FileManager.default.fileExists(atPath: home.path("Library/Developer/Xcode/Archives/2026-10-01")) == false)
        #expect(FileManager.default.fileExists(atPath: home.path("Library/Developer/Xcode/Archives/2026-10-02/b.txt")))
    }
}
