import Foundation

nonisolated struct WorkspaceError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

nonisolated struct LiveWorkspaceActions: WorkspaceActing {
    let shell: ShellRunner

    func revealInFinder(path: String) async throws {
        try await open(path: path, with: "Finder")
    }

    func open(path: String, with application: String) async throws {
        try await execute("open", ["-a", application, path])
    }

    func openTerminal(at path: String, terminal: TerminalApp) async throws {
        if terminal == .ghostty {
            try await execute("open", ["-na", "Ghostty", "--args", "--working-directory=\(path)"])
        } else {
            try await open(path: path, with: terminal.applicationName)
        }
    }

    func runInTerminal(command: String, at path: String, terminal: TerminalApp) async throws {
        let script = try writeScript(command: command, cwd: path)
        if terminal == .ghostty {
            try await execute("open", ["-na", "Ghostty", "--args", "-e", script])
        } else {
            try await execute("open", ["-a", terminal.applicationName, script])
        }
    }

    func openTarget(_ target: String) async throws {
        try await execute("open", [target])
    }

    private func writeScript(command: String, cwd: String) throws -> String {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("devhub-\(UUID().uuidString).command")
        try TerminalScript.build(command: command, cwd: cwd).write(to: url, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
        return url.path
    }

    private func execute(_ executable: String, _ arguments: [String]) async throws {
        let result = try await shell.run(executable, arguments, cwd: nil)
        guard result.exitCode == 0 else {
            throw WorkspaceError(message: result.failureMessage)
        }
    }
}
