import Foundation
import DevHubDomain

struct CircleCIClient {
    let shell: ShellRunner

    func run(_ arguments: [String], project: CIProject) async throws -> Data {
        let result = try await output(arguments, project: project)
        guard result.exitCode == 0 else { throw Self.error(exitCode: result.exitCode, message: result.failureMessage) }
        return Data(result.stdout.utf8)
    }

    func output(_ arguments: [String], project: CIProject) async throws -> ShellResult {
        let result: ShellResult
        do {
            result = try await shell.run("circleci", arguments, cwd: project.checkoutPath)
        } catch {
            throw CIError.notInstalled
        }
        guard result.exitCode != 127 else { throw CIError.notInstalled }
        return result
    }

    static func error(exitCode: Int32, message: String) -> CIError {
        if exitCode == 127 || message.contains("command not found") || message.contains("No such file") {
            return .notInstalled
        }
        let lowered = message.lowercased()
        let loginHints = ["not logged in", "unauthorized", "401", "auth login", "no token", "not authenticated", "set token"]
        if loginHints.contains(where: lowered.contains) {
            return .notLoggedIn
        }
        return .command(message)
    }

    static func versionArguments() -> [String] {
        ["version", "--json"]
    }

    static func settingArguments() -> [String] {
        ["setting", "list", "--json"]
    }

    static func workflowArguments(id: String, slug: String?) -> [String] {
        withProject(["workflow", "get", id, "--json"], slug: slug)
    }

    static func runListArguments(branch: String, limit: Int, slug: String?) -> [String] {
        withProject(["run", "list", "--branch", branch, "--limit", String(limit), "--json"], slug: slug)
    }

    static func jobOutputArguments(jobID: String, slug: String?) -> [String] {
        withProject(["job", "output", "list", jobID, "--json"], slug: slug)
    }

    static func testResultArguments(jobID: String, slug: String?) -> [String] {
        withProject(["testresult", "list", jobID, "--json"], slug: slug)
    }

    static func flakyTestsArguments(slug: String) -> [String] {
        ["api", "api/v2/insights/\(slug)/flaky-tests"]
    }

    static func rerunArguments(workflowID: String, fromFailed: Bool, slug: String?) -> [String] {
        withProject(["workflow", "rerun", workflowID] + (fromFailed ? ["--from-failed"] : []) + ["--json"], slug: slug)
    }

    static func cancelArguments(workflowID: String, slug: String?) -> [String] {
        withProject(["workflow", "cancel", workflowID, "--force"], slug: slug)
    }

    static func approveArguments(runID: String, job: String, slug: String?) -> [String] {
        withProject(["run", "approve", runID, "--job", job, "--force", "--json"], slug: slug)
    }

    private static func withProject(_ arguments: [String], slug: String?) -> [String] {
        guard let slug, slug.isEmpty == false else { return arguments }
        return arguments + ["--project", slug]
    }
}
