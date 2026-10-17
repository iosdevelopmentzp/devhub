import Foundation
import DevHubDomain

package actor ShellRunner {
    nonisolated let recorder: any CommandRecording

    private static let extraPath = ["/opt/homebrew/bin", "/usr/local/bin"]
    fileprivate nonisolated static let blockingQueue = DispatchQueue(label: "DevHub.ShellRunner", attributes: .concurrent)

    package init(recorder: any CommandRecording) {
        self.recorder = recorder
    }

    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?) async throws -> ShellResult {
        try await run(executable, arguments, cwd: cwd, environment: [:])
    }

    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) async throws -> ShellResult {
        let id = UUID()
        let kind = CommandKind.classify(executable, arguments)
        recorder.record(CommandEvent(id: id, payload: .started(command: CommandFormatter.displayCommand(executable, arguments), cwd: cwd, kind: kind)))
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                Self.blockingQueue.async {
                    continuation.resume(with: Result { try Self.runBlocking(executable, arguments, cwd: cwd, environment: environment) })
                }
            }
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
        let process = Self.makeProcess(executable, arguments, cwd: cwd, environment: [:])
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let id = UUID()
        let batcher = LineBatcher(id: id, recorder: recorder)
        let kind = CommandKind.classify(executable, arguments)
        recorder.record(CommandEvent(id: id, payload: .started(command: CommandFormatter.displayCommand(executable, arguments), cwd: cwd, kind: kind == .read ? .action : kind)))
        do {
            try process.run()
        } catch {
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: nil, error: error.localizedDescription)))
            throw error
        }
        let handle = ProcessHandle(process)
        do {
            let status = try await withTaskCancellationHandler {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    if kind.hidesOutput == false {
                        batcher.add(line)
                    }
                    onLine(line)
                }
                process.waitUntilExit()
                return process.terminationStatus
            } onCancel: {
                handle.terminate()
            }
            batcher.flush()
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: status, error: Task.isCancelled ? "Cancelled" : nil)))
            return status
        } catch {
            batcher.flush()
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: nil, error: error.localizedDescription)))
            throw error
        }
    }

    private nonisolated static func runBlocking(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) throws -> ShellResult {
        let process = makeProcess(executable, arguments, cwd: cwd, environment: environment)
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try process.run()
        let stderrReader = DataReader(stderrPipe.fileHandleForReading)
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrReader.wait()
        process.waitUntilExit()
        return ShellResult(
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }

    private nonisolated static func makeProcess(_ executable: String, _ arguments: [String], cwd: String?, environment extra: [String: String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        var environment = ProcessInfo.processInfo.environment
        let path = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = (extraPath + [path]).joined(separator: ":")
        environment.merge(extra) { _, new in new }
        process.environment = environment
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }
        return process
    }
}

private nonisolated final class DataReader: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private var data = Data()

    init(_ handle: FileHandle) {
        ShellRunner.blockingQueue.async { [self] in
            data = handle.readDataToEndOfFile()
            semaphore.signal()
        }
    }

    func wait() -> Data {
        semaphore.wait()
        return data
    }
}

private nonisolated final class ProcessHandle: @unchecked Sendable {
    private let process: Process

    init(_ process: Process) {
        self.process = process
    }

    func terminate() {
        guard process.isRunning else { return }
        process.terminate()
    }
}
