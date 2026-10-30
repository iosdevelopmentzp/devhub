import Foundation
import DevHubDomain

final class ProcessOutput: @unchecked Sendable {
    private enum Part {
        case stdout
        case stderr
        case exit
    }

    private let lock = NSLock()
    private let process: Process
    private var stdout = Data()
    private var stderr = Data()
    private var openParts: Set<Part> = [.stdout, .stderr, .exit]
    private var continuation: CheckedContinuation<ShellResult, any Error>?

    private init(process: Process, continuation: CheckedContinuation<ShellResult, any Error>) {
        self.process = process
        self.continuation = continuation
    }

    static func run(_ process: Process) async throws -> ShellResult {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        return try await withCheckedThrowingContinuation { continuation in
            let output = ProcessOutput(process: process, continuation: continuation)
            output.read(stdoutPipe.fileHandleForReading, as: .stdout)
            output.read(stderrPipe.fileHandleForReading, as: .stderr)
            process.terminationHandler = { _ in output.close(.exit) }
            do {
                try process.run()
            } catch {
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil
                process.terminationHandler = nil
                output.resume(with: .failure(error))
            }
        }
    }

    private func read(_ handle: FileHandle, as part: Part) {
        handle.readabilityHandler = { [self] handle in
            let chunk = handle.availableData
            guard chunk.isEmpty == false else {
                handle.readabilityHandler = nil
                close(part)
                return
            }
            lock.withLock {
                if part == .stdout {
                    stdout.append(chunk)
                } else {
                    stderr.append(chunk)
                }
            }
        }
    }

    private func close(_ part: Part) {
        let isFinished = lock.withLock {
            openParts.remove(part)
            return openParts.isEmpty
        }
        guard isFinished else { return }
        let result = lock.withLock {
            ShellResult(stdout: String(decoding: stdout, as: UTF8.self), stderr: String(decoding: stderr, as: UTF8.self), exitCode: process.terminationStatus)
        }
        resume(with: .success(result))
    }

    private func resume(with result: Result<ShellResult, any Error>) {
        let continuation = lock.withLock {
            let current = self.continuation
            self.continuation = nil
            return current
        }
        continuation?.resume(with: result)
    }
}
