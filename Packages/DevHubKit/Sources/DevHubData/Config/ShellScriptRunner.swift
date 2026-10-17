import Foundation
import DevHubDomain

struct ShellScriptRunner: ScriptRunning {
    let shell: ShellRunner

    func run(_ request: ScriptRunRequest) -> AsyncThrowingStream<ScriptEvent, any Error> {
        let shell = shell
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let status = try await withThrowingTaskGroup(of: Int32?.self) { group in
                        group.addTask {
                            let (executable, arguments) = Self.invocation(request)
                            return try await shell.stream(executable, arguments, cwd: request.cwd, environment: request.environment) { line in
                                continuation.yield(.output(line))
                            }
                        }
                        if let timeout = request.timeout {
                            group.addTask {
                                try await Task.sleep(for: timeout)
                                return nil
                            }
                        }
                        let first = try await group.next() ?? nil
                        group.cancelAll()
                        guard let first else {
                            throw ScriptError.timedOut(request.timeout ?? .zero)
                        }
                        return first
                    }
                    continuation.yield(.exited(status))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    static func invocation(_ request: ScriptRunRequest) -> (executable: String, arguments: [String]) {
        let path = request.executable
        let isFile = path.contains("/") && FileManager.default.fileExists(atPath: path)
        guard isFile, FileManager.default.isExecutableFile(atPath: path) == false else { return (path, request.arguments) }
        return ("/bin/zsh", [path] + request.arguments)
    }
}
