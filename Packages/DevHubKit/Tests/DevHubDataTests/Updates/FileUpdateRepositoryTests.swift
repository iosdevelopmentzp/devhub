import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct FileUpdateRepositoryTests {
    private let directory: TemporaryDirectory
    private let repository: FileUpdateRepository

    init() throws {
        directory = try TemporaryDirectory()
        repository = FileUpdateRepository(shell: ShellRunner(recorder: SpyCommandRecorder()), supportFolder: directory.url)
    }

    @Test func missingFilesGiveNoInstalledBuildStatusOrLog() async throws {
        #expect(try await repository.installed() == nil)
        #expect(try await repository.status() == nil)
        #expect(try await repository.log() == nil)
        #expect(await repository.isUpdateRunning() == false)
        try await repository.clearStatus()
    }

    @Test func installedJSONIsRead() async throws {
        _ = try directory.write(
            "{\"commit\": \"0123456789abcdef0123456789abcdef01234567\", \"branch\": \"main\", \"source\": \"/Users/alex/Library/Application Support/Example App/source\", \"installedAt\": \"2026-11-07T10:00:00Z\"}\n",
            to: "update/installed.json"
        )

        let installed = try #require(try await repository.installed())

        #expect(installed.commit == "0123456789abcdef0123456789abcdef01234567")
        #expect(installed.branch == "main")
        #expect(installed.source == "/Users/alex/Library/Application Support/Example App/source")
        #expect(installed.installedAt == Date(timeIntervalSince1970: 1_794_045_600))
    }

    @Test func statusJSONIsReadWithNulls() async throws {
        _ = try directory.write("{\"phase\": \"building\", \"startedAt\": \"2026-11-07T10:00:00Z\", \"commit\": null, \"message\": null}\n", to: "update/status.json")

        let status = try #require(try await repository.status())

        #expect(status == UpdateStatus(phase: .building, startedAt: Date(timeIntervalSince1970: 1_794_045_600)))
    }

    @Test func aBrokenStatusFileThrows() async throws {
        _ = try directory.write("{\"phase\": \"flying\"}", to: "update/status.json")

        await #expect(throws: (any Error).self) {
            try await repository.status()
        }
    }

    @Test func clearStatusRemovesTheFile() async throws {
        let file = try directory.write("{\"phase\": \"done\", \"startedAt\": \"2026-11-07T10:00:00Z\", \"commit\": \"abc\", \"message\": null}", to: "update/status.json")

        try await repository.clearStatus()

        #expect(FileManager.default.fileExists(atPath: file.path) == false)
    }

    @Test func theLockFileNamesTheRunningProcess() async throws {
        _ = try directory.write("\(ProcessInfo.processInfo.processIdentifier)\n", to: "update/update.lock")
        #expect(await repository.isUpdateRunning())

        _ = try directory.write("2147483647\n", to: "update/update.lock")
        #expect(await repository.isUpdateRunning() == false)

        _ = try directory.write("not a pid", to: "update/update.lock")
        #expect(await repository.isUpdateRunning() == false)
    }

    @Test func theLogIsReadAsText() async throws {
        _ = try directory.write("$ Scripts/install.sh\nlayers: ok\n", to: "update/update.log")

        #expect(try await repository.log() == "$ Scripts/install.sh\nlayers: ok\n")
    }

    @Test func startNeedsTheScriptInTheSource() async throws {
        let installed = InstalledBuild(commit: "abc", branch: "main", source: directory.path("source"), installedAt: .now)

        await #expect(throws: UpdateError.scriptMissing(directory.path("source/Scripts/update.sh"))) {
            try await repository.start(installed: installed)
        }
    }
}
