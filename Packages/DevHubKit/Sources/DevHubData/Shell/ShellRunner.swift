import Foundation
import DevHubDomain

package actor ShellRunner {
    nonisolated let recorder: any CommandRecording
    nonisolated let developerDir = DeveloperDirState()

    private static let extraPath = ["/opt/homebrew/bin", "/usr/local/bin"]

    package init(recorder: any CommandRecording) {
        self.recorder = recorder
    }

    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?) async throws -> ShellResult {
        try await run(executable, arguments, cwd: cwd, environment: [:])
    }

    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) async throws -> ShellResult {
        let id = UUID()
        let kind = CommandKind.classify(executable, arguments)
        recorder.record(CommandEvent(id: id, payload: .started(command: CommandFormatter.displayCommand(executable, arguments), cwd: cwd, kind: kind, operationID: OperationScope.current)))
        do {
            let result = try await ProcessOutput.run(Self.makeProcess(executable, arguments, cwd: cwd, environment: environment, developerDir: developerDir.value))
            if kind.hidesOutput == false {
                let text = [result.stdout, result.stderr].filter { $0.trimmed.isEmpty == false }.joined(separator: "\n")
                let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                if lines.isEmpty == false, text.isEmpty == false {
                    recorder.record(CommandEvent(id: id, payload: .output(lines)))
                }
            }
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: result.exitCode, error: nil)))
            return result
        } catch {
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: nil, error: error.localizedDescription)))
            throw error
        }
    }

    func stream(
        _ executable: String,
        _ arguments: [String],
        cwd: String?,
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        try await stream(executable, arguments, cwd: cwd, environment: [:], onLine: onLine)
    }

    func stream(
        _ executable: String,
        _ arguments: [String],
        cwd: String?,
        environment: [String: String],
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        try await stream(executable, arguments, cwd: cwd, environment: environment, stop: .terminate, onLine: onLine)
    }

    func stream(
        _ executable: String,
        _ arguments: [String],
        cwd: String?,
        environment: [String: String],
        stop: ProcessStop,
        onLine: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        let process = Self.makeProcess(executable, arguments, cwd: cwd, environment: environment, developerDir: developerDir.value)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let exit = ProcessExit()
        process.terminationHandler = { exit.finish($0.terminationStatus) }
        let id = UUID()
        let batcher = LineBatcher(id: id, recorder: recorder)
        let kind = CommandKind.classify(executable, arguments)
        recorder.record(CommandEvent(id: id, payload: .started(command: CommandFormatter.displayCommand(executable, arguments), cwd: cwd, kind: kind == .read ? .action : kind, operationID: OperationScope.current)))
        do {
            try process.run()
        } catch {
            process.terminationHandler = nil
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: nil, error: error.localizedDescription)))
            throw error
        }
        let handle = ProcessHandle(process)
        do {
            let status = try await withTaskCancellationHandler {
                for await line in ProcessLines.lines(of: pipe.fileHandleForReading) {
                    if kind.hidesOutput == false {
                        batcher.add(line)
                    }
                    onLine(line)
                }
                return await exit.status()
            } onCancel: {
                handle.stop(stop)
            }
            batcher.flush()
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: status, error: Task.isCancelled && stop == .terminate ? "Cancelled" : nil)))
            return status
        } catch {
            batcher.flush()
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: nil, error: error.localizedDescription)))
            throw error
        }
    }

    private nonisolated static func makeProcess(_ executable: String, _ arguments: [String], cwd: String?, environment extra: [String: String], developerDir: String?) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        process.environment = environment(for: executable, base: ProcessInfo.processInfo.environment, extra: extra, developerDir: developerDir)
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }
        return process
    }

    nonisolated static func environment(for executable: String, base: [String: String], extra: [String: String], developerDir: String?) -> [String: String] {
        var environment = base.merging(TelemetryOptOutPolicy.environment) { _, optOut in optOut }
        let path = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = (extraPath + [path]).joined(separator: ":")
        if let developerDir, DeveloperDirPolicy.applies(to: executable) {
            environment["DEVELOPER_DIR"] = developerDir
        }
        environment.merge(extra) { _, new in new }
        return environment
    }
}

private nonisolated final class ProcessHandle: @unchecked Sendable {
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    func stop(_ stop: ProcessStop) {
        guard process.isRunning else { return }
        switch stop {
        case .terminate:
            process.terminate()
        case .interrupt:
            process.interrupt()
        }
    }
}

private nonisolated final class ProcessExit: @unchecked Sendable {
    private let lock = NSLock()
    private var code: Int32?
    private var continuation: CheckedContinuation<Int32, Never>?

    func finish(_ code: Int32) {
        let waiting = lock.withLock {
            self.code = code
            let current = continuation
            continuation = nil
            return current
        }
        waiting?.resume(returning: code)
    }

    func status() async -> Int32 {
        await withCheckedContinuation { continuation in
            let finished: Int32? = lock.withLock {
                if let code { return code }
                self.continuation = continuation
                return nil
            }
            if let finished {
                continuation.resume(returning: finished)
            }
        }
    }
}
