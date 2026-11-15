import Foundation
import DevHubDomain

struct JiraClient {
    let shell: ShellRunner
    let executable: String
    let environment: JiraShellEnvironment

    func run(_ arguments: [String]) async throws -> Data {
        let result = try await output(arguments)
        guard result.exitCode == 0 else { throw Self.error(exitCode: result.exitCode, message: result.failureMessage) }
        return Data(result.stdout.utf8)
    }

    func output(_ arguments: [String]) async throws -> ShellResult {
        if await environment.isNeeded {
            return try await launch(arguments, environment: await environment.read())
        }
        let result = try await launch(arguments, environment: [:])
        guard Self.isLoginFailure(result) else { return result }
        let variables = await environment.read()
        guard variables.isEmpty == false else { return result }
        let retried = try await launch(arguments, environment: variables)
        if Self.isLoginFailure(retried) == false {
            await environment.markNeeded()
        }
        return retried
    }

    func launch(_ arguments: [String], environment: [String: String]) async throws -> ShellResult {
        let result: ShellResult
        do {
            result = try await shell.run(executable, arguments, cwd: nil, environment: environment)
        } catch {
            throw TrackerError.notInstalled
        }
        guard result.exitCode != 127 else { throw TrackerError.notInstalled }
        return result
    }

    static func isLoginFailure(_ result: ShellResult) -> Bool {
        result.exitCode != 0 && error(exitCode: result.exitCode, message: result.failureMessage) == .notLoggedIn
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

    static func issueListArguments(jql: String, project: String?, order: IssueOrder, limit: Int) -> [String] {
        var arguments = ["issue", "list", "-q", jql, "--raw", "--paginate", "0:\(limit)", "--order-by", order.rawValue]
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

    static func assignArguments(key: String, user: String) -> [String] {
        ["issue", "assign", key, user]
    }

    static func unassignArguments(key: String) -> [String] {
        ["issue", "assign", key, "x"]
    }

    static func watchArguments(key: String, user: String) -> [String] {
        ["issue", "watch", key, user]
    }

    static func commentArguments(key: String, text: String) -> [String] {
        ["issue", "comment", "add", "--no-input", "--", key, text]
    }
}
