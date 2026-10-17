import Foundation

nonisolated struct GitFailure: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

nonisolated struct GitShell: Sendable {
    let shell: ShellRunner

    func run(_ arguments: [String], at path: String, environment: [String: String] = [:]) async throws -> ShellResult {
        try await shell.run("git", arguments, cwd: path, environment: environment)
    }

    func output(_ arguments: [String], at path: String) async throws -> String {
        let result = try await run(arguments, at: path)
        guard result.exitCode == 0 else {
            throw GitFailure(message: result.failureMessage)
        }
        return result.stdout
    }

    func optionalOutput(_ arguments: [String], at path: String) async -> String? {
        guard let result = try? await run(arguments, at: path), result.exitCode == 0 else { return nil }
        return result.stdout
    }
}
