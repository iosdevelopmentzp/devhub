import Foundation
import DevHubDomain

struct FileUpdateRepository: UpdateRepository {
    let shell: ShellRunner
    let supportFolder: URL

    static let scriptPath = "Scripts/update.sh"

    init(shell: ShellRunner, supportFolder: URL) {
        self.shell = shell
        self.supportFolder = supportFolder
    }

    var updateFolder: URL {
        supportFolder.appendingPathComponent("update", isDirectory: true)
    }

    var installedFile: URL {
        updateFolder.appendingPathComponent("installed.json")
    }

    var statusFile: URL {
        updateFolder.appendingPathComponent("status.json")
    }

    var logFile: URL {
        updateFolder.appendingPathComponent("update.log")
    }

    var lockFile: URL {
        updateFolder.appendingPathComponent("update.lock")
    }

    func installed() async throws -> InstalledBuild? {
        try read(InstalledBuild.self, from: installedFile)
    }

    func check(installed: InstalledBuild) async throws -> UpdateCheck {
        let fetch = try await git(["fetch", "--quiet", "origin", installed.branch], in: installed.source)
        guard fetch.exitCode == 0 else { throw UpdateError.git(fetch.failureMessage) }
        let ancestor = try await git(["merge-base", "--is-ancestor", installed.commit, installed.remoteBranch], in: installed.source)
        guard ancestor.exitCode == 0 else {
            return UpdateCheckPolicy.result(installedIsOnRemote: false, newCommits: [])
        }
        let log = try await git(["log", "--format=%h%x1f%s", "\(installed.commit)..\(installed.remoteBranch)"], in: installed.source)
        guard log.exitCode == 0 else { throw UpdateError.git(log.failureMessage) }
        return UpdateCheckPolicy.result(installedIsOnRemote: true, newCommits: UpdateCommitParser.commits(from: log.stdout))
    }

    func start(installed: InstalledBuild) async throws {
        let script = URL(fileURLWithPath: installed.source).appendingPathComponent(Self.scriptPath).path
        guard FileManager.default.isExecutableFile(atPath: script) else { throw UpdateError.scriptMissing(script) }
        guard await isUpdateRunning() == false else { throw UpdateError.alreadyRunning }
        try FileManager.default.createDirectory(at: updateFolder, withIntermediateDirectories: true)
        let command = "\(quoted(script)) > \(quoted(logFile.path)) 2>&1 < /dev/null &!"
        let result = try await shell.run("zsh", ["-c", command], cwd: installed.source, environment: ["DEVHUB_SUPPORT_DIR": supportFolder.path])
        guard result.exitCode == 0 else { throw UpdateError.git(result.failureMessage) }
    }

    func status() async throws -> UpdateStatus? {
        try read(UpdateStatus.self, from: statusFile)
    }

    func isUpdateRunning() async -> Bool {
        guard let text = try? String(contentsOf: lockFile, encoding: .utf8), let pid = Int32(text.trimmed) else { return false }
        return kill(pid, 0) == 0 || errno == EPERM
    }

    func clearStatus() async throws {
        guard FileManager.default.fileExists(atPath: statusFile.path) else { return }
        try FileManager.default.removeItem(at: statusFile)
    }

    func log() async throws -> String? {
        guard FileManager.default.fileExists(atPath: logFile.path) else { return nil }
        return try String(contentsOf: logFile, encoding: .utf8)
    }

    private func read<T: Decodable>(_ type: T.Type, from file: URL) throws -> T? {
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: Data(contentsOf: file))
    }

    private func git(_ arguments: [String], in source: String) async throws -> ShellResult {
        try await shell.run("git", ["-C", source] + arguments, cwd: nil)
    }

    private func quoted(_ path: String) -> String {
        "\"" + path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }
}
