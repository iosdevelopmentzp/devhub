import Foundation

nonisolated protocol AppLogProviding: Sendable {
    func stream(simulatorID: String, filter: LogFilter) -> AsyncThrowingStream<LogLine, Error>
}

nonisolated struct MockAppLogProvider: AppLogProviding {
    func stream(simulatorID: String, filter: LogFilter) -> AsyncThrowingStream<LogLine, Error> {
        AsyncThrowingStream { continuation in
            let samples: [(LogLine.Level, String, String)] = [
                (.info, "network", "Request started"),
                (.notice, "network", "Response received in 120 ms"),
                (.error, "storage", "Could not read cache file"),
                (.info, "ui", "Screen appeared")
            ]
            for sample in samples {
                continuation.yield(LogLine(id: UUID(), date: Date(), level: sample.0, subsystem: "sample", category: sample.1, message: sample.2))
            }
            continuation.finish()
        }
    }
}
