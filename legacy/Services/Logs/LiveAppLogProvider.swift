import Foundation

nonisolated struct LogStreamError: LocalizedError, Sendable {
    let message: String

    var errorDescription: String? { message }
}

nonisolated struct LiveAppLogProvider: AppLogProviding {
    let shell: ShellRunner

    func stream(simulatorID: String, filter: LogFilter) -> AsyncThrowingStream<LogLine, Error> {
        AsyncThrowingStream { continuation in
            var arguments = ["simctl", "spawn", simulatorID, "log", "stream", "--style", "ndjson", "--level", "debug"]
            if let predicate = filter.predicate {
                arguments += ["--predicate", predicate]
            }
            let task = Task { [shell, arguments] in
                let parser = LogLineParser()
                do {
                    let code = try await shell.stream("xcrun", arguments, cwd: nil) { line in
                        guard let parsed = parser.parse(line) else { return }
                        continuation.yield(parsed)
                    }
                    if code == 0 {
                        continuation.finish()
                    } else {
                        continuation.finish(throwing: LogStreamError(message: "The log stream stopped with code \(code). Is the simulator still booted?"))
                    }
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
