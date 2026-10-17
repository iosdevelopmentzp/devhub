import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct CommandLogRecorderTests {
    @Test func recordedEventLandsInTheLog() async throws {
        let log = CommandLog()
        let recorder = CommandLogRecorder(log: log)
        let id = UUID()

        recorder.record(CommandEvent(id: id, payload: .started(command: "git status", cwd: nil, kind: .read)))

        try await waitUntil { log.entries.isEmpty == false }
        #expect(log.entries.first?.id == id)
    }

    @Test func eventsFromABackgroundTaskArriveInOrder() async throws {
        let log = CommandLog()
        let recorder = CommandLogRecorder(log: log)
        let id = UUID()

        await Task.detached {
            recorder.record(CommandEvent(id: id, payload: .started(command: "git fetch", cwd: nil, kind: .action)))
            recorder.record(CommandEvent(id: id, payload: .output(["done"])))
            recorder.record(CommandEvent(id: id, payload: .finished(exitCode: 0, error: nil)))
        }.value

        try await waitUntil { log.entries.first?.isRunning == false }
        #expect(log.entries.first?.lines == ["done"])
        #expect(log.entries.first?.exitCode == 0)
    }
}
