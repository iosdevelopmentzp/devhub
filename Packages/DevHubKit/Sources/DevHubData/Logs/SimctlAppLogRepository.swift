import Foundation
import DevHubDomain

struct SimctlAppLogRepository: AppLogRepository {
    let shell: ShellRunner

    func executableName(udid: String, bundleID: String) async -> String? {
        guard let result = try? await shell.run("xcrun", ["simctl", "get_app_container", udid, bundleID, "app"], cwd: nil),
              result.exitCode == 0 else { return nil }
        let info = URL(fileURLWithPath: result.stdout.trimmed).appendingPathComponent("Info.plist")
        return PlistReader.dictionary(at: info)?["CFBundleExecutable"] as? String
    }

    func stream(udid: String, filter: AppLogFilter) -> AsyncThrowingStream<AppLogLine, Error> {
        AsyncThrowingStream { continuation in
            let counter = LogCounter()
            let task = Task {
                do {
                    var arguments = ["simctl", "spawn", udid, "log", "stream", "--style", "ndjson", "--level", "debug"]
                    if let predicate = AppLogPredicatePolicy.predicate(for: filter) {
                        arguments += ["--predicate", predicate]
                    }
                    let status = try await shell.stream("xcrun", arguments, cwd: nil) { line in
                        guard let parsed = AppLogParser.parse(line, id: counter.next()) else { return }
                        continuation.yield(parsed)
                    }
                    if status != 0, Task.isCancelled == false {
                        continuation.finish(throwing: AppLogError.streamStopped(status))
                    } else {
                        continuation.finish()
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
