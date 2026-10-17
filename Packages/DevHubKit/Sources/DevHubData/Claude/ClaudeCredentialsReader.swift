import Foundation
import DevHubDomain

struct ClaudeCredentialsReader {
    let shell: ShellRunner

    private static let keychainService = "Claude Code-credentials"
    private static let fallbackFile = "~/.claude/.credentials.json"

    func read() async throws -> ClaudeCredentials {
        let json = try await keychainJSON() ?? fileJSON()
        guard let json else { throw ClaudeUsageError.notLoggedIn }
        return try ClaudeCredentialsParser.parse(json)
    }

    private func keychainJSON() async throws -> Data? {
        let result = try await shell.run("security", ["find-generic-password", "-s", Self.keychainService, "-w"], cwd: nil)
        guard result.exitCode == 0 else { return nil }
        let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return Data(trimmed.utf8)
    }

    private func fileJSON() -> Data? {
        let path = (Self.fallbackFile as NSString).expandingTildeInPath
        return FileManager.default.contents(atPath: path)
    }
}
