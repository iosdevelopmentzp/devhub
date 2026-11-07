import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite(.tags(.integration)) struct FileUpdateRepositoryIntegrationTests {
    private let repo: TemporaryGitRepository
    private let support: TemporaryDirectory
    private let repository: FileUpdateRepository
    private let clone: String

    init() async throws {
        repo = try await TemporaryGitRepository()
        support = try TemporaryDirectory()
        clone = support.path("source")
        try await repo.git(["clone", "--quiet", "--branch", "main", repo.path, clone], in: repo.root)
        repository = FileUpdateRepository(shell: repo.shell, supportFolder: support.url)
    }

    @Test func behindTheRemoteListsTheNewCommits() async throws {
        let installed = try await installedBuild(at: "HEAD~1")
        try repo.write("third\n", to: "third.txt")
        try await repo.commitAll("Third commit")

        let check = try await repository.check(installed: installed)

        guard case .available(let commits) = check else {
            Issue.record("expected available, got \(check)")
            return
        }
        #expect(commits.map(\.subject) == ["Third commit", "Second commit"])
        #expect(commits.allSatisfy { $0.hash.count >= 7 })
    }

    @Test func equalToTheRemoteIsUpToDate() async throws {
        let installed = try await installedBuild(at: "HEAD")

        #expect(try await repository.check(installed: installed) == .upToDate)
    }

    @Test func aCommitThatIsNotOnTheRemoteIsUnknown() async throws {
        let feature = try await repo.git("rev-parse", "feature").trimmed
        let installed = InstalledBuild(commit: feature, branch: "main", source: clone, installedAt: .now)

        #expect(try await repository.check(installed: installed) == .unknownInstalledCommit)
    }

    @Test func startRunsTheScriptDetachedWithTheSupportFolder() async throws {
        let installed = try await installedBuild(at: "HEAD")
        let marker = support.path("marker.txt")
        let script = (clone as NSString).appendingPathComponent(FileUpdateRepository.scriptPath)
        try repo.write("#!/bin/zsh\necho \"$DEVHUB_SUPPORT_DIR\" > \"\(marker)\"\necho started\n", at: script)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: script)

        try await repository.start(installed: installed)

        try await waitUntil { FileManager.default.fileExists(atPath: marker) }
        #expect(try String(contentsOfFile: marker, encoding: .utf8) == support.url.path + "\n")
        let log = support.path("update/update.log")
        try await waitUntil { (try? String(contentsOfFile: log, encoding: .utf8))?.contains("started") == true }
        #expect(try await repository.log()?.contains("started") == true)
    }

    private func installedBuild(at revision: String) async throws -> InstalledBuild {
        let commit = try await repo.git("rev-parse", revision).trimmed
        return InstalledBuild(commit: commit, branch: "main", source: clone, installedAt: .now)
    }
}
