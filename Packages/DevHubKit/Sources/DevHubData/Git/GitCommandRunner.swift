import Foundation
import DevHubDomain

struct GitCommandRunner: Sendable {
    let shell: ShellRunner

    func run(_ arguments: [String], in directory: String, environment: [String: String] = [:]) async throws -> String {
        let result = try await result(arguments, in: directory, environment: environment)
        guard result.exitCode == 0 else { throw WorktreeError.command(result.failureMessage) }
        return result.stdout
    }

    func result(_ arguments: [String], in directory: String, environment: [String: String] = [:]) async throws -> ShellResult {
        try await shell.run("git", arguments, cwd: directory, environment: environment)
    }
}
