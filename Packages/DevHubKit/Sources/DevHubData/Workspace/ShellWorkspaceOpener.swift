import Foundation
import DevHubDomain

struct ShellWorkspaceOpener: WorkspaceOpening {
    let shell: ShellRunner

    func openTerminal(_ app: String, at path: String) async -> String? {
        let expanded = (path as NSString).expandingTildeInPath
        let arguments: [String]
        switch app {
        case "Ghostty":
            arguments = ["-na", "Ghostty", "--args", "--working-directory=\(expanded)"]
        default:
            arguments = ["-a", app, expanded]
        }
        do {
            let result = try await shell.run("open", arguments, cwd: nil)
            guard result.exitCode == 0 else {
                return result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func runInTerminal(_ app: String, at path: String, command: String) async -> String? {
        let expanded = (path as NSString).expandingTildeInPath
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("DevHub", isDirectory: true)
        let script = folder.appendingPathComponent("run-\(UUID().uuidString).command")
        let body = """
        #!/bin/zsh
        rm -f "$0"
        cd \(expanded.shellQuoted) || exit 1
        exec "${SHELL:-/bin/zsh}" -i -l -c \("\(command); exec \"${SHELL:-/bin/zsh}\" -i -l".shellQuoted)
        """
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try body.write(to: script, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
        } catch {
            return error.localizedDescription
        }
        let arguments: [String]
        switch app {
        case "Ghostty":
            arguments = ["-na", "Ghostty", "--args", "--working-directory=\(expanded)", "-e", script.path]
        default:
            arguments = ["-a", app, script.path]
        }
        do {
            let result = try await shell.run("open", arguments, cwd: nil)
            return result.exitCode == 0 ? nil : result.failureMessage
        } catch {
            return error.localizedDescription
        }
    }

    func openInEditor(_ editor: String, path: String) async -> String? {
        let app = editor == "VS Code" ? "Visual Studio Code" : editor
        do {
            let result = try await shell.run("open", ["-a", app, (path as NSString).expandingTildeInPath], cwd: nil)
            return result.exitCode == 0 ? nil : result.failureMessage
        } catch {
            return error.localizedDescription
        }
    }

    func openFile(_ path: String, line: Int?) async -> String? {
        let arguments = (line.map { ["--line", String($0)] } ?? []) + [(path as NSString).expandingTildeInPath]
        do {
            let result = try await shell.run("xed", arguments, cwd: nil)
            return result.exitCode == 0 ? nil : result.failureMessage
        } catch {
            return error.localizedDescription
        }
    }

    func openInXcode(_ path: String) async -> String? {
        let target: String
        if let container = try? XcodeContainer.locate(in: path) {
            target = container.url.path
        } else {
            target = (path as NSString).expandingTildeInPath
        }
        do {
            let result = try await shell.run("open", ["-a", "Xcode", target], cwd: nil)
            return result.exitCode == 0 ? nil : result.failureMessage
        } catch {
            return error.localizedDescription
        }
    }
}
