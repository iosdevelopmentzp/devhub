import DevHubTestSupport
import Foundation
@testable import DevHubData

final class TemporaryGitRepository {
    let recorder = SpyCommandRecorder()
    let shell: ShellRunner
    let root: String
    let path: String
    let linkedPath: String
    private let directory: TemporaryDirectory

    init() async throws {
        directory = try TemporaryDirectory()
        shell = ShellRunner(recorder: recorder)
        root = try Self.realPath(directory.url.path)
        path = (root as NSString).appendingPathComponent("repo")
        linkedPath = (root as NSString).appendingPathComponent("repo-linked")
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)

        try await git("init", "-b", "main")
        try await git("config", "user.email", "tests@example.com")
        try await git("config", "user.name", "DevHub Tests")
        try await git("config", "commit.gpgsign", "false")
        try await git("config", "core.hooksPath", "/dev/null")
        try write("hello\n", to: "README.md")
        try await commitAll("Initial commit")
        try write("hello\nmore\n", to: "README.md")
        try await commitAll("Second commit")
        try await git("branch", "merged-branch")
        try await git("switch", "-c", "feature")
        try write("feature\n", to: "feature.txt")
        try await commitAll("Add feature")
        try await git("switch", "main")
        try await git("worktree", "add", "-b", "linked", linkedPath)
    }

    @discardableResult
    func git(_ arguments: String...) async throws -> String {
        try await git(arguments, in: path)
    }

    @discardableResult
    func git(_ arguments: [String], in directory: String) async throws -> String {
        let result = try await shell.run("git", arguments, cwd: directory, environment: [:])
        guard result.exitCode == 0 else { throw TestError.scripted(result.failureMessage) }
        return result.stdout
    }

    func commitAll(_ message: String) async throws {
        try await git("add", "-A")
        try await git("commit", "-q", "-m", message)
    }

    @discardableResult
    func write(_ text: String, to relativePath: String) throws -> String {
        try write(text, at: (path as NSString).appendingPathComponent(relativePath))
    }

    @discardableResult
    func write(_ text: String, at file: String) throws -> String {
        try FileManager.default.createDirectory(atPath: (file as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try text.write(toFile: file, atomically: true, encoding: .utf8)
        return file
    }

    func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    private static func realPath(_ path: String) throws -> String {
        guard let resolved = realpath(path, nil) else { throw TestError.scripted("realpath failed for \(path)") }
        defer { free(resolved) }
        return String(cString: resolved)
    }
}
