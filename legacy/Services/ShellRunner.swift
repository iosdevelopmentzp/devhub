import Foundation

nonisolated struct ShellResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32

    var failureMessage: String {
        let error = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        if error.isEmpty == false {
            return error
        }
        let output = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if output.isEmpty == false {
            return output
        }
        return "Exited with code \(exitCode)."
    }
}

actor ShellRunner {
    nonisolated static let shared = ShellRunner(recorder: .shared)

    private nonisolated let recorder: CommandRecorder
    private nonisolated let queue = DispatchQueue(label: "DevHub.ShellRunner", attributes: .concurrent)

    init(recorder: CommandRecorder) {
        self.recorder = recorder
    }

    nonisolated func run(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String] = [:]) async throws -> ShellResult {
        let id = begin(executable, arguments, cwd: cwd)
        let kind = CommandClassifier.classify(executable: executable, arguments: arguments)
        let process = Self.makeProcess(executable, arguments, cwd: cwd, environment: environment)
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ShellResult, Error>) in
                queue.async { [queue] in
                    do {
                        continuation.resume(returning: try Self.runBlocking(process, queue: queue))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            if kind == .action || kind == .read {
                let lines = (result.stdout + result.stderr).split(whereSeparator: \.isNewline).map(String.init)
                recorder.send(.output(id: id, lines: lines))
            }
            recorder.send(.finished(id: id, exitCode: result.exitCode, error: nil, date: Date()))
            return result
        } catch {
            recorder.send(.finished(id: id, exitCode: nil, error: error.localizedDescription, date: Date()))
            throw error
        }
    }

    func stream(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String] = [:], onLine: @escaping @Sendable (String) -> Void) async throws -> Int32 {
        let id = begin(executable, arguments, cwd: cwd)
        let kind = CommandClassifier.classify(executable: executable, arguments: arguments)
        let batcher = LineBatcher(id: id, recorder: recorder, recordsOutput: kind == .action || kind == .read)
        let process = Self.makeProcess(executable, arguments, cwd: cwd, environment: environment)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            recorder.send(.finished(id: id, exitCode: nil, error: error.localizedDescription, date: Date()))
            throw error
        }
        do {
            try await withTaskCancellationHandler {
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    onLine(line)
                    batcher.add(line)
                }
            } onCancel: {
                process.terminate()
            }
        } catch {
            process.terminate()
            await waitForExit(process)
            batcher.flush()
            let message = error is CancellationError ? CommandEntry.cancelledMessage : error.localizedDescription
            recorder.send(.finished(id: id, exitCode: nil, error: message, date: Date()))
            throw error
        }
        await waitForExit(process)
        batcher.flush()
        let status = process.terminationStatus
        let cancelMessage = Task.isCancelled ? CommandEntry.cancelledMessage : nil
        recorder.send(.finished(id: id, exitCode: status, error: cancelMessage, date: Date()))
        try Task.checkCancellation()
        return status
    }

    private nonisolated func begin(_ executable: String, _ arguments: [String], cwd: String?) -> UUID {
        let id = UUID()
        recorder.send(.started(
            id: id,
            command: CommandDisplay.format(executable: executable, arguments: arguments),
            cwd: cwd,
            kind: CommandClassifier.classify(executable: executable, arguments: arguments),
            date: Date()
        ))
        return id
    }

    private nonisolated func waitForExit(_ process: Process) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                process.waitUntilExit()
                continuation.resume()
            }
        }
    }

    private nonisolated static func makeProcess(_ executable: String, _ arguments: [String], cwd: String?, environment: [String: String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [executable] + arguments
        if let cwd {
            process.currentDirectoryURL = URL(fileURLWithPath: (cwd as NSString).expandingTildeInPath)
        }
        var merged = ProcessInfo.processInfo.environment
        let inherited = merged["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        merged["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + inherited
        for (key, value) in environment {
            merged[key] = value
        }
        process.environment = merged
        process.standardInput = FileHandle.nullDevice
        return process
    }

    private nonisolated static func runBlocking(_ process: Process, queue: DispatchQueue) throws -> ShellResult {
        let output = Pipe()
        let errors = Pipe()
        process.standardOutput = output
        process.standardError = errors
        try process.run()
        let errorReader = DataReader(handle: errors.fileHandleForReading, queue: queue)
        let outputData = output.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorReader.wait()
        process.waitUntilExit()
        return ShellResult(
            stdout: String(decoding: outputData, as: UTF8.self),
            stderr: String(decoding: errorData, as: UTF8.self),
            exitCode: process.terminationStatus
        )
    }
}

nonisolated final class DataReader: @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private var data = Data()

    init(handle: FileHandle, queue: DispatchQueue) {
        queue.async { [self] in
            data = handle.readDataToEndOfFile()
            semaphore.signal()
        }
    }

    func wait() -> Data {
        semaphore.wait()
        return data
    }
}
