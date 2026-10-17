import Foundation
import DevHubDomain

struct MockAppLogRepository: AppLogRepository {

    func executableName(udid: String, bundleID: String) async -> String? {
        "ExampleApp"
    }

    func stream(udid: String, process: String) -> AsyncThrowingStream<AppLogLine, Error> {
        AsyncThrowingStream { continuation in
            let samples: [(AppLogLine.Level, String, String)] = [
                (.info, "com.example.app · network", "GET /v1/profile/info 200 in 182 ms"),
                (.notice, "com.example.app · calls", "Call prompt shown for gift 42"),
                (.error, "com.example.app · calls", "Call prompt translation is missing: call.prompt.title"),
                (.debug, "com.example.app · ui", "LeaderboardView appeared")
            ]
            let task = Task {
                for index in 0..<40 {
                    let sample = samples[index % samples.count]
                    continuation.yield(AppLogLine(id: index, date: .now, level: sample.0, category: sample.1, message: sample.2))
                    try? await Task.sleep(for: .milliseconds(300))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
