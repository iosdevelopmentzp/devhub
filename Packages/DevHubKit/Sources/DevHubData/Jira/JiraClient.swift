import Foundation
import DevHubDomain

struct JiraClient {
    let shell: ShellRunner

    func run(_ arguments: [String]) async throws -> Data {
        let result = try await output(arguments)
        guard result.exitCode == 0 else { throw Self.error(exitCode: result.exitCode, message: result.failureMessage) }
        return Data(result.stdout.utf8)
    }

    func output(_ arguments: [String]) async throws -> ShellResult {
        let result: ShellResult
        do {
            result = try await shell.run("jira", arguments, cwd: nil)
        } catch {
            throw TrackerError.notInstalled
        }
        guard result.exitCode != 127 else { throw TrackerError.notInstalled }
        return result
    }

    static func error(exitCode: Int32, message: String) -> TrackerError {
        let plain = plainText(message)
        if exitCode == 127 || plain.contains("command not found") || plain.contains("No such file") {
            return .notInstalled
        }
        let lowered = plain.lowercased()
        if lowered.contains("api token") || lowered.contains("unauthorized") || lowered.contains("401") || lowered.contains("not authenticated") {
            return .notLoggedIn
        }
        if lowered.contains("jira init") || (lowered.contains("config") && lowered.contains("not found")) {
            return .notConfigured
        }
        return .command(plain)
    }

    static func plainText(_ message: String) -> String {
        let pattern = "\u{1B}\\[[0-9;]*[A-Za-z]"
        return message.replacingOccurrences(of: pattern, with: "", options: .regularExpression).trimmed
    }

    static func versionArguments() -> [String] {
        ["version"]
    }

    static func meArguments() -> [String] {
        ["me"]
    }

    static func issueListArguments(jql: String, project: String?, limit: Int) -> [String] {
        var arguments = ["issue", "list", "-q", jql, "--raw", "--paginate", "0:\(limit)", "--order-by", "updated"]
        if let project, project.isEmpty == false {
            arguments += ["-p", project]
        }
        return arguments
    }

    static func issueViewArguments(key: String) -> [String] {
        ["issue", "view", key, "--raw"]
    }

    static func moveArguments(key: String, status: String) -> [String] {
        ["issue", "move", key, status]
    }
}
