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
                            try await shell.stream(request.executable, request.arguments, cwd: request.cwd, environment: request.environment) { line in
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
}
