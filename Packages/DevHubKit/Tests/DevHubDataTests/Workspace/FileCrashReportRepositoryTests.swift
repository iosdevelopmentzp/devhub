import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileCrashReportRepositoryTests {
    private let folder: TemporaryDirectory
    private let repository: FileCrashReportRepository

    init() throws {
        folder = try TemporaryDirectory()
        repository = FileCrashReportRepository(root: folder.url)
    }

    @Test func listsOnlyNewSimulatorCrashes() async throws {
        let old = try folder.write(CrashReportFixture.simulatorCrash, to: "ExampleApp-old.ips")
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSince1970: 1_000)], ofItemAtPath: old.path)
        _ = try folder.write(CrashReportFixture.simulatorCrash, to: "ExampleApp-new.ips")
        _ = try folder.write(CrashReportFixture.macCrash, to: "Notes-new.ips")
        _ = try folder.write(CrashReportFixture.hang, to: "ExampleApp-hang.ips")
        _ = try folder.write(CrashReportFixture.simulatorCrash, to: "ExampleApp-new.txt")

        let reports = try await repository.reports(since: Date(timeIntervalSince1970: 2_000))

        #expect(reports.map { URL(fileURLWithPath: $0.path).lastPathComponent } == ["ExampleApp-new.ips"])
        #expect(reports.first?.bundleID == "com.example.app")
    }

    @Test func aMissingFolderHasNoReports() async throws {
        let missing = FileCrashReportRepository(root: folder.url.appendingPathComponent("missing"))

        #expect(try await missing.reports(since: .distantPast).isEmpty)
    }

    @Test(.timeLimit(.minutes(1))) func aNewFileWakesTheStream() async throws {
        let changes = repository.changes()
        let woke = Task {
            for await _ in changes {
                return true
            }
            return false
        }

        await Task.yield()
        _ = try folder.write(CrashReportFixture.simulatorCrash, to: "ExampleApp-live.ips")

        #expect(await woke.value)
    }
}
